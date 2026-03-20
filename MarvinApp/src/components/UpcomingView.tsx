import { CalendarDays } from 'lucide-react';
import type { AppStore } from '../store';
import { TaskCard } from './TaskCard';
import { AddTaskBar } from './AddTaskBar';
import { todayString, formatDate } from '../utils';

interface Props {
  store: AppStore;
}

function getNext14Days(): string[] {
  const days: string[] = [];
  const today = new Date();
  for (let i = 0; i < 14; i++) {
    const d = new Date(today);
    d.setDate(today.getDate() + i);
    days.push(d.toISOString().split('T')[0]);
  }
  return days;
}

export function UpcomingView({ store }: Props) {
  const { state } = store;
  const { tasks } = state;

  const days = getNext14Days();
  const today = todayString();

  const scheduledTasks = tasks.filter(t => !t.done && t.scheduledFor && t.scheduledFor >= today);
  const unscheduledWithDue = tasks.filter(t => !t.done && !t.scheduledFor && t.dueDate);

  const byDay = new Map<string, typeof tasks>();
  days.forEach(d => byDay.set(d, []));
  scheduledTasks.forEach(task => {
    if (task.scheduledFor && byDay.has(task.scheduledFor)) {
      byDay.get(task.scheduledFor)!.push(task);
    }
  });

  return (
    <div className="flex-1 overflow-y-auto p-6">
      <div className="max-w-2xl mx-auto space-y-6">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <CalendarDays size={20} className="text-indigo-400" />
            <h1 className="text-2xl font-bold text-white">Upcoming</h1>
          </div>
          <p className="text-white/40 text-sm">Next 14 days</p>
        </div>

        {days.map(day => {
          const dayTasks = byDay.get(day) || [];
          if (dayTasks.length === 0 && day !== today) return null;
          return (
            <div key={day}>
              <div className="flex items-center gap-2 mb-3">
                <span className={`text-sm font-semibold ${day === today ? 'text-purple-400' : 'text-white/60'}`}>
                  {formatDate(day)}
                </span>
                {day === today && (
                  <span className="text-xs bg-purple-500/20 text-purple-400 px-2 py-0.5 rounded-full">Today</span>
                )}
                <span className="text-xs text-white/20">{dayTasks.length} tasks</span>
              </div>
              {dayTasks.length > 0 ? (
                <div className="space-y-2">
                  {dayTasks.map(task => (
                    <TaskCard key={task.id} task={task} store={store} showProject />
                  ))}
                </div>
              ) : (
                <div className="border border-dashed border-white/10 rounded-xl p-4 text-center text-sm text-white/20">
                  No tasks scheduled
                </div>
              )}
            </div>
          );
        })}

        {unscheduledWithDue.length > 0 && (
          <div>
            <div className="text-sm font-semibold text-white/40 mb-3">With due dates (unscheduled)</div>
            <div className="space-y-2">
              {unscheduledWithDue.map(task => (
                <TaskCard key={task.id} task={task} store={store} showProject />
              ))}
            </div>
          </div>
        )}

        <AddTaskBar store={store} placeholder="Add upcoming task..." />
      </div>
    </div>
  );
}
