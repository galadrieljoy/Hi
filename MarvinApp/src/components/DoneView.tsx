import { CheckSquare, Trash2 } from 'lucide-react';
import type { AppStore } from '../store';
import { TaskCard } from './TaskCard';
import { todayString } from '../utils';

interface Props {
  store: AppStore;
}

export function DoneView({ store }: Props) {
  const { state, deleteTask } = store;
  const { tasks } = state;

  const doneTasks = tasks
    .filter(t => t.done)
    .sort((a, b) => (b.doneAt || 0) - (a.doneAt || 0));

  const today = todayString();
  const doneToday = doneTasks.filter(t => {
    if (!t.doneAt) return false;
    return new Date(t.doneAt).toISOString().split('T')[0] === today;
  });
  const doneEarlier = doneTasks.filter(t => {
    if (!t.doneAt) return true;
    return new Date(t.doneAt).toISOString().split('T')[0] !== today;
  });

  const totalPoints = doneTasks.reduce((sum, t) => sum + t.points, 0);

  function clearAll() {
    if (confirm('Clear all completed tasks?')) {
      doneTasks.forEach(t => deleteTask(t.id));
    }
  }

  return (
    <div className="flex-1 overflow-y-auto p-6">
      <div className="max-w-2xl mx-auto space-y-6">
        <div className="flex items-start justify-between">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <CheckSquare size={20} className="text-green-400" />
              <h1 className="text-2xl font-bold text-white">Completed</h1>
            </div>
            <p className="text-white/40 text-sm">{doneTasks.length} tasks · {totalPoints} points earned</p>
          </div>
          {doneTasks.length > 0 && (
            <button
              onClick={clearAll}
              className="flex items-center gap-1.5 text-sm text-white/30 hover:text-red-400 transition-colors"
            >
              <Trash2 size={14} />
              Clear all
            </button>
          )}
        </div>

        {doneToday.length > 0 && (
          <div>
            <div className="text-sm font-semibold text-white/50 mb-3">Today</div>
            <div className="space-y-2">
              {doneToday.map(task => (
                <TaskCard key={task.id} task={task} store={store} showProject />
              ))}
            </div>
          </div>
        )}

        {doneEarlier.length > 0 && (
          <div>
            <div className="text-sm font-semibold text-white/30 mb-3">Earlier</div>
            <div className="space-y-1.5">
              {doneEarlier.map(task => (
                <TaskCard key={task.id} task={task} store={store} showProject />
              ))}
            </div>
          </div>
        )}

        {doneTasks.length === 0 && (
          <div className="text-center py-16 text-white/20">
            <div className="text-5xl mb-4">🏁</div>
            <div className="text-lg font-medium mb-1">Nothing completed yet</div>
            <div className="text-sm">Complete tasks to see them here</div>
          </div>
        )}
      </div>
    </div>
  );
}
