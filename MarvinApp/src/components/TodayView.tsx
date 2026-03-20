import { Sun, Star, Clock } from 'lucide-react';
import type { AppStore } from '../store';
import { TaskCard } from './TaskCard';
import { AddTaskBar } from './AddTaskBar';
import { todayString, getTotalTime, formatDuration } from '../utils';

interface Props {
  store: AppStore;
}

export function TodayView({ store }: Props) {
  const { state } = store;
  const { tasks } = state;

  const today = todayString();
  const todayTasks = tasks.filter(t => t.scheduledFor === today && !t.done);
  const doneTodayTasks = tasks.filter(t => t.scheduledFor === today && t.done);
  const todayPoints = doneTodayTasks.reduce((sum, t) => sum + t.points, 0);
  const totalTracked = tasks
    .filter(t => t.scheduledFor === today)
    .reduce((sum, t) => sum + getTotalTime(t.timeEntries), 0);

  const starredTasks = todayTasks.filter(t => t.isStarred);
  const regularTasks = todayTasks.filter(t => !t.isStarred);

  const now = new Date();
  const hours = now.getHours();
  const greeting = hours < 12 ? 'Good morning' : hours < 17 ? 'Good afternoon' : 'Good evening';

  const dateStr = now.toLocaleDateString('en-US', {
    weekday: 'long', month: 'long', day: 'numeric'
  });

  return (
    <div className="flex-1 overflow-y-auto p-6">
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Header */}
        <div>
          <div className="flex items-center gap-2 mb-1">
            <Sun size={20} className="text-yellow-400" />
            <h1 className="text-2xl font-bold text-white">{greeting}!</h1>
          </div>
          <p className="text-white/40 text-sm">{dateStr}</p>
        </div>

        {/* Stats bar */}
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-white/5 border border-white/10 rounded-xl p-3 text-center">
            <div className="text-2xl font-bold text-white">{todayTasks.length}</div>
            <div className="text-xs text-white/40 mt-0.5">Remaining</div>
          </div>
          <div className="bg-white/5 border border-white/10 rounded-xl p-3 text-center">
            <div className="text-2xl font-bold text-green-400">{doneTodayTasks.length}</div>
            <div className="text-xs text-white/40 mt-0.5">Done today</div>
          </div>
          <div className="bg-white/5 border border-white/10 rounded-xl p-3 text-center">
            <div className="text-2xl font-bold text-yellow-400">+{todayPoints}</div>
            <div className="text-xs text-white/40 mt-0.5">Points earned</div>
          </div>
        </div>

        {totalTracked > 0 && (
          <div className="flex items-center gap-2 text-sm text-white/50">
            <Clock size={14} />
            <span>{formatDuration(totalTracked)} tracked today</span>
          </div>
        )}

        {/* Starred tasks */}
        {starredTasks.length > 0 && (
          <div>
            <div className="flex items-center gap-2 mb-3">
              <Star size={14} className="text-yellow-400" fill="currentColor" />
              <span className="text-sm font-semibold text-white/70">Starred</span>
            </div>
            <div className="space-y-2">
              {starredTasks.map(task => (
                <TaskCard key={task.id} task={task} store={store} showProject />
              ))}
            </div>
          </div>
        )}

        {/* Regular tasks */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <span className="text-sm font-semibold text-white/70">Tasks</span>
            {todayTasks.length === 0 && doneTodayTasks.length === 0 && (
              <span className="text-xs text-white/30">Schedule tasks from your inbox</span>
            )}
          </div>
          <div className="space-y-2">
            {regularTasks.map(task => (
              <TaskCard key={task.id} task={task} store={store} showProject />
            ))}
          </div>
        </div>

        {/* Add task */}
        <AddTaskBar store={store} scheduleToday placeholder="Add task for today..." />

        {/* Done today */}
        {doneTodayTasks.length > 0 && (
          <div>
            <div className="flex items-center gap-2 mb-3">
              <span className="text-sm font-semibold text-white/40">Completed ({doneTodayTasks.length})</span>
            </div>
            <div className="space-y-1.5">
              {doneTodayTasks.map(task => (
                <TaskCard key={task.id} task={task} store={store} showProject />
              ))}
            </div>
          </div>
        )}

        {todayTasks.length === 0 && doneTodayTasks.length === 0 && (
          <div className="text-center py-16 text-white/20">
            <div className="text-5xl mb-4">🌅</div>
            <div className="text-lg font-medium mb-1">Your day is clear!</div>
            <div className="text-sm">Add tasks or schedule from your inbox</div>
          </div>
        )}
      </div>
    </div>
  );
}
