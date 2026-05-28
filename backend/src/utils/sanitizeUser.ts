import { IUser } from '../models/User';

export function sanitizeUser(user: IUser) {
  const obj = user.toObject();
  delete (obj as { password?: string }).password;
  return obj;
}
