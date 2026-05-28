import mongoose from 'mongoose';

const DEFAULT_URI = 'mongodb://localhost:27017/smartmedic';

export async function connectDatabase(): Promise<void> {
  const uri = process.env.MONGODB_URI || DEFAULT_URI;
  mongoose.set('strictQuery', true);
  await mongoose.connect(uri);
  console.log(`MongoDB conectado: ${mongoose.connection.name}`);
}

export async function disconnectDatabase(): Promise<void> {
  await mongoose.disconnect();
}
