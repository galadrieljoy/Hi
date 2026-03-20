import type { Task, TimeEntry } from './types';

export function generateId(): string {
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}

export function getTotalTime(entries: TimeEntry[]): number {
  return entries.reduce((sum, e) => {
    const end = e.end ?? Date.now();
    return sum + (end - e.start);
  }, 0);
}

export function formatDuration(ms: number): string {
  const secs = Math.floor(ms / 1000);
  const h = Math.floor(secs / 3600);
  const m = Math.floor((secs % 3600) / 60);
  const s = secs % 60;
  if (h > 0) return `${h}h ${m}m`;
  if (m > 0) return `${m}m ${s}s`;
  return `${s}s`;
}

export function isTimerRunning(task: Task): boolean {
  const last = task.timeEntries[task.timeEntries.length - 1];
  return !!last && !last.end;
}

export function formatDate(dateStr: string): string {
  const date = new Date(dateStr + 'T00:00:00');
  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(today.getDate() + 1);
  if (dateStr === today.toISOString().split('T')[0]) return 'Today';
  if (dateStr === tomorrow.toISOString().split('T')[0]) return 'Tomorrow';
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

export function todayString(): string {
  return new Date().toISOString().split('T')[0];
}

export function getPriorityColor(priority: string): string {
  switch (priority) {
    case 'high': return '#ef4444';
    case 'medium': return '#f59e0b';
    case 'low': return '#3b82f6';
    default: return 'transparent';
  }
}

export function levelFromPoints(points: number): number {
  return Math.floor(points / 100) + 1;
}

export function pointsToNextLevel(points: number): number {
  return 100 - (points % 100);
}
