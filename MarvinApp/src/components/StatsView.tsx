import { BarChart2, Star, Clock, CheckSquare, Zap } from 'lucide-react';
import type { AppStore } from '../store';
import { getTotalTime, formatDuration, todayString, pointsToNextLevel } from '../utils';

interface Props {
  store: AppStore;
}

export function StatsView({ store }: Props) {
  const { state } = store;
  const { tasks, projects, totalPoints, level } = state;

  const today = todayString();
  const doneTasks = tasks.filter(t => t.done);
  const doneToday = doneTasks.filter(t => t.doneAt && new Date(t.doneAt).toISOString().split('T')[0] === today);
  const totalTracked = tasks.reduce((sum, t) => sum + getTotalTime(t.timeEntries), 0);
  const todayTracked = tasks
    .filter(t => t.scheduledFor === today)
    .reduce((sum, t) => sum + getTotalTime(t.timeEntries), 0);

  const completionRate = tasks.length > 0
    ? Math.round((doneTasks.length / tasks.length) * 100)
    : 0;

  const highPriorityDone = doneTasks.filter(t => t.priority === 'high').length;
  const totalHigh = tasks.filter(t => t.priority === 'high').length;

  // Project breakdown
  const projectStats = projects.map(p => {
    const pTasks = tasks.filter(t => t.projectId === p.id);
    const done = pTasks.filter(t => t.done).length;
    return { project: p, total: pTasks.length, done, pct: pTasks.length > 0 ? Math.round((done / pTasks.length) * 100) : 0 };
  }).sort((a, b) => b.total - a.total);

  // Last 7 days completion
  const last7 = Array.from({ length: 7 }, (_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (6 - i));
    const dateStr = d.toISOString().split('T')[0];
    const count = doneTasks.filter(t => t.doneAt && new Date(t.doneAt).toISOString().split('T')[0] === dateStr).length;
    return { dateStr, count, label: d.toLocaleDateString('en-US', { weekday: 'short' }) };
  });
  const maxCount = Math.max(...last7.map(d => d.count), 1);

  const ptsToNext = pointsToNextLevel(totalPoints);

  return (
    <div className="flex-1 overflow-y-auto p-6">
      <div className="max-w-2xl mx-auto space-y-6">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <BarChart2 size={20} className="text-cyan-400" />
            <h1 className="text-2xl font-bold text-white">Stats</h1>
          </div>
          <p className="text-white/40 text-sm">Your productivity overview</p>
        </div>

        {/* Level card */}
        <div className="bg-gradient-to-r from-purple-900/60 to-blue-900/60 border border-purple-500/20 rounded-2xl p-5">
          <div className="flex items-center justify-between mb-3">
            <div>
              <div className="text-xs text-white/50 mb-1">Current Level</div>
              <div className="text-4xl font-bold text-white">{level}</div>
            </div>
            <div className="text-right">
              <div className="text-xs text-white/50 mb-1">Total Points</div>
              <div className="text-2xl font-bold text-yellow-400 flex items-center gap-1">
                <Star size={18} fill="currentColor" /> {totalPoints}
              </div>
            </div>
          </div>
          <div className="h-2 bg-white/10 rounded-full overflow-hidden mb-1">
            <div
              className="h-full bg-gradient-to-r from-purple-500 to-blue-500 rounded-full transition-all"
              style={{ width: `${totalPoints % 100}%` }}
            />
          </div>
          <div className="text-xs text-white/40">{ptsToNext} points to level {level + 1}</div>
        </div>

        {/* Key metrics */}
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-white/5 border border-white/10 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <CheckSquare size={16} className="text-green-400" />
              <span className="text-xs text-white/50">Total Done</span>
            </div>
            <div className="text-3xl font-bold text-white">{doneTasks.length}</div>
            <div className="text-xs text-white/30 mt-1">{doneToday.length} today</div>
          </div>
          <div className="bg-white/5 border border-white/10 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <Zap size={16} className="text-yellow-400" />
              <span className="text-xs text-white/50">Completion Rate</span>
            </div>
            <div className="text-3xl font-bold text-white">{completionRate}%</div>
            <div className="text-xs text-white/30 mt-1">{highPriorityDone}/{totalHigh} high priority</div>
          </div>
          <div className="bg-white/5 border border-white/10 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <Clock size={16} className="text-blue-400" />
              <span className="text-xs text-white/50">Time Tracked</span>
            </div>
            <div className="text-3xl font-bold text-white">{formatDuration(totalTracked)}</div>
            <div className="text-xs text-white/30 mt-1">{formatDuration(todayTracked)} today</div>
          </div>
          <div className="bg-white/5 border border-white/10 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <Star size={16} className="text-purple-400" />
              <span className="text-xs text-white/50">Active Tasks</span>
            </div>
            <div className="text-3xl font-bold text-white">{tasks.filter(t => !t.done).length}</div>
            <div className="text-xs text-white/30 mt-1">{tasks.filter(t => !t.done && t.scheduledFor === today).length} today</div>
          </div>
        </div>

        {/* Last 7 days chart */}
        <div className="bg-white/5 border border-white/10 rounded-xl p-4">
          <div className="text-sm font-semibold text-white/60 mb-4">Tasks completed (last 7 days)</div>
          <div className="flex items-end gap-2 h-24">
            {last7.map(day => (
              <div key={day.dateStr} className="flex-1 flex flex-col items-center gap-1">
                <span className="text-xs text-white/40">{day.count || ''}</span>
                <div className="w-full flex flex-col justify-end" style={{ height: '60px' }}>
                  <div
                    className="w-full rounded-t-sm transition-all"
                    style={{
                      height: `${(day.count / maxCount) * 100}%`,
                      minHeight: day.count > 0 ? '4px' : '0',
                      backgroundColor: day.dateStr === today ? '#8b5cf6' : '#4c1d95',
                      opacity: day.count > 0 ? 1 : 0.2,
                    }}
                  />
                </div>
                <span className="text-xs text-white/30">{day.label}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Project breakdown */}
        {projectStats.length > 0 && (
          <div className="bg-white/5 border border-white/10 rounded-xl p-4">
            <div className="text-sm font-semibold text-white/60 mb-4">Projects</div>
            <div className="space-y-3">
              {projectStats.map(({ project, total, done, pct }) => (
                <div key={project.id}>
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm text-white/70">{project.icon} {project.name}</span>
                    <span className="text-xs text-white/40">{done}/{total}</span>
                  </div>
                  <div className="h-1.5 bg-white/10 rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all"
                      style={{ width: `${pct}%`, backgroundColor: project.color }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
