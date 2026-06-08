import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { BackendRealtimeClient, applyBroadcasts } from './backendClient';
import { config } from './config';
import { socketIoCorsConfig } from './config/cors';

type AuthPayload = { id: string; role: string };
type AuthedSocket = Socket & { data: { user: AuthPayload } };

export function initSocketServer(
  httpServer: HttpServer,
  backend: BackendRealtimeClient,
): Server {
  const io = new Server(httpServer, {
    cors: socketIoCorsConfig(),
    transports: ['polling', 'websocket'],
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth?.token as string | undefined;
    if (!token) {
      return next(new Error('Token requerido'));
    }
    try {
      const user = jwt.verify(token, config.jwtSecret) as AuthPayload;
      socket.data.user = user;
      next();
    } catch {
      next(new Error('Token inválido'));
    }
  });

  io.on('connection', (socket: AuthedSocket) => {
    const userId = socket.data.user.id;
    const role = socket.data.user.role;
    socket.join(`user:${userId}`);

    if (role === 'CLINIC_ADMIN') {
      void backend
        .clinicAdminRooms(userId)
        .then(({ rooms }) => {
          for (const room of rooms) {
            socket.join(room);
          }
        })
        .catch(() => undefined);
    }

    if (role === 'AMBULANCE_DRIVER') {
      void backend
        .driverRooms(userId)
        .then(({ rooms }) => {
          for (const room of rooms) {
            socket.join(room);
          }
        })
        .catch(() => undefined);
    }

    if (role === 'PARAMEDIC' || role === 'AMBULANCE_NURSE') {
      void backend
        .driverRooms(userId)
        .then(({ rooms }) => {
          for (const room of rooms) {
            socket.join(room);
          }
        })
        .catch(() => undefined);
    }

    socket.on('conversation:join', async (conversationId: string) => {
      try {
        const result = await backend.conversationJoin(userId, conversationId);
        if (result.ok) {
          socket.join(`conversation:${conversationId}`);
        }
      } catch {
        // ignore
      }
    });

    socket.on('conversation:leave', (conversationId: string) => {
      socket.leave(`conversation:${conversationId}`);
    });

    socket.on(
      'message:send',
      async (
        payload: { conversationId: string; text: string; kind?: 'chat' | 'clinical' },
        ack?: (response: { ok: boolean; error?: string; message?: unknown }) => void,
      ) => {
        try {
          const result = await backend.messageSend(userId, payload);
          applyBroadcasts(io, result.broadcasts);
          const ackBody = result.ack ?? { ok: true };
          ack?.(ackBody as { ok: boolean; error?: string; message?: unknown });
        } catch (e) {
          ack?.({ ok: false, error: (e as Error).message });
        }
      },
    );

    socket.on('typing:start', (payload: { conversationId: string }) => {
      socket.to(`conversation:${payload.conversationId}`).emit('typing:start', {
        conversationId: payload.conversationId,
        userId,
      });
    });

    socket.on('typing:stop', (payload: { conversationId: string }) => {
      socket.to(`conversation:${payload.conversationId}`).emit('typing:stop', {
        conversationId: payload.conversationId,
        userId,
      });
    });

    socket.on(
      'call:invite',
      async (
        payload: {
          conversationId: string;
          callType: 'video' | 'audio';
          callerName?: string;
        },
        ack?: (response: { ok: boolean; calleeId?: string; error?: string }) => void,
      ) => {
        try {
          const callRoom = `call:${payload.conversationId}`;
          socket.join(callRoom);
          const result = await backend.callInvite(userId, payload);
          applyBroadcasts(io, result.broadcasts);
          const calleeRoom = result.broadcasts.find((b) => b.room.startsWith('user:'));
          const calleeId = calleeRoom?.room.replace(/^user:/, '');
          const ok = result.broadcasts.length > 0;
          if (process.env.NODE_ENV !== 'production') {
            console.log(
              `[call] invite caller=${userId} callee=${calleeId ?? 'none'} conv=${payload.conversationId} delivered=${ok}`,
            );
          }
          ack?.({
            ok,
            calleeId,
            error: ok
              ? undefined
              : 'No se pudo avisar al destinatario (conversación o cita no válida)',
          });
        } catch (e) {
          ack?.({ ok: false, error: (e as Error).message });
        }
      },
    );

    socket.on('call:join', (payload: { conversationId: string }) => {
      if (payload?.conversationId) {
        socket.join(`call:${payload.conversationId}`);
      }
    });

    socket.on('call:leave', (payload: { conversationId: string }) => {
      if (payload?.conversationId) {
        socket.leave(`call:${payload.conversationId}`);
      }
    });

    const emitHandlerBroadcasts = (broadcasts: import('./types').RealtimeBroadcast[]) => {
      for (const b of broadcasts) {
        if (b.room.startsWith('call:')) {
          socket.to(b.room).emit(b.event, b.payload);
        } else {
          io.to(b.room).emit(b.event, b.payload);
        }
      }
    };

    socket.on('call:accept', async (payload: { conversationId: string }) => {
      try {
        const callRoom = `call:${payload.conversationId}`;
        socket.join(callRoom);
        const result = await backend.callAccept(userId, payload.conversationId);
        emitHandlerBroadcasts(result.broadcasts);
      } catch {
        // ignore
      }
    });

    socket.on('call:reject', async (payload: { conversationId: string }) => {
      try {
        const result = await backend.callReject(userId, payload.conversationId);
        emitHandlerBroadcasts(result.broadcasts);
      } catch {
        // ignore
      }
    });

    const emitCallSignaling = async (
      payload: { conversationId: string },
      event: string,
      body: Record<string, unknown>,
    ) => {
      const { peerId } = await backend.callPeer(userId, payload.conversationId);
      if (!peerId) return;

      const callRoom = `call:${payload.conversationId}`;
      const signalId = `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
      const message = { ...body, fromUserId: userId, signalId };

      socket.join(callRoom);
      socket.to(callRoom).emit(event, message);
      io.to(`user:${peerId}`).emit(event, message);
    };

    socket.on(
      'call:offer',
      (payload: { conversationId: string; sdp: unknown; callType?: string }) => {
        void emitCallSignaling(payload, 'call:offer', {
          conversationId: payload.conversationId,
          sdp: payload.sdp,
          callType: payload.callType,
        });
      },
    );

    socket.on('call:answer', (payload: { conversationId: string; sdp: unknown }) => {
      void emitCallSignaling(payload, 'call:answer', {
        conversationId: payload.conversationId,
        sdp: payload.sdp,
      });
    });

    socket.on(
      'call:ice',
      (payload: { conversationId: string; candidate: unknown }) => {
        void emitCallSignaling(payload, 'call:ice', {
          conversationId: payload.conversationId,
          candidate: payload.candidate,
        });
      },
    );

    socket.on('call:end', async (payload: { conversationId: string }) => {
      try {
        const result = await backend.callEnd(userId, payload.conversationId);
        emitHandlerBroadcasts(result.broadcasts);
        socket.leave(`call:${payload.conversationId}`);
      } catch {
        // ignore
      }
    });

    socket.on('emergency:join', async (emergencyRequestId: string) => {
      try {
        const result = await backend.emergencyJoin(userId, emergencyRequestId);
        if (result.ok) {
          socket.join(`emergency:${emergencyRequestId}`);
        }
      } catch {
        // ignore
      }
    });

    socket.on('emergency:leave', (emergencyRequestId: string) => {
      socket.leave(`emergency:${emergencyRequestId}`);
    });

    socket.on(
      'emergency:message:send',
      async (
        payload: { emergencyRequestId: string; text: string },
        ack?: (response: { ok: boolean; error?: string; message?: unknown }) => void,
      ) => {
        try {
          const result = await backend.emergencyMessageSend(userId, payload);
          applyBroadcasts(io, result.broadcasts);
          const ackBody = result.ack ?? { ok: true };
          ack?.(ackBody as { ok: boolean; error?: string; message?: unknown });
        } catch (e) {
          ack?.({ ok: false, error: (e as Error).message });
        }
      },
    );

    socket.on(
      'emergency:call:invite',
      async (
        payload: {
          emergencyRequestId: string;
          callType: 'video' | 'audio';
          callerName?: string;
        },
        ack?: (response: { ok: boolean; calleeId?: string; error?: string }) => void,
      ) => {
        try {
          const callRoom = `call:${payload.emergencyRequestId}`;
          socket.join(callRoom);
          const result = await backend.emergencyCallInvite(userId, payload);
          applyBroadcasts(io, result.broadcasts);
          const calleeRoom = result.broadcasts.find((b) => b.room.startsWith('user:'));
          const calleeId = calleeRoom?.room.replace(/^user:/, '');
          const ok = result.broadcasts.length > 0;
          ack?.({
            ok,
            calleeId,
            error: ok ? undefined : 'No se pudo avisar al destinatario',
          });
        } catch (e) {
          ack?.({ ok: false, error: (e as Error).message });
        }
      },
    );
  });

  return io;
}
