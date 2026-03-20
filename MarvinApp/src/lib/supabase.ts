import { createClient } from '@supabase/supabase-js';
import type { AppState } from '../types';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL as string;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY as string;

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export async function loadCloudState(userId: string): Promise<AppState | null> {
  const { data, error } = await supabase
    .from('user_data')
    .select('state')
    .eq('id', userId)
    .single();
  if (error || !data) return null;
  return data.state as AppState;
}

export async function saveCloudState(userId: string, state: AppState): Promise<void> {
  await supabase
    .from('user_data')
    .upsert({ id: userId, state, updated_at: new Date().toISOString() });
}
