import { Calendar, Inbox, CalendarDays, FolderOpen, CheckSquare, BarChart2, Plus, Star } from 'lucide-react';
import type { AppStore } from '../store';
import type { View, Project } from '../types';
import { todayString } from '../utils';

interface Props {
  store: AppStore;
}

const PROJECT_COLORS = [
  '#7c3aed', '#2563eb', '#16a34a', '#dc2626', '#d97706',
  '#db2777', '#0891b2', '#65a30d', '#7c3aed', '#ea580c',
];

export function Sidebar({ store }: Props) {
  const { state, setView, addProject } = store;
  const { selectedView, selectedProjectId, projects, tasks, totalPoints, level } = state;

  const todayCount = tasks.filter(t => !t.done && t.scheduledFor === todayString()).length;
  const inboxCount = tasks.filter(t => !t.done && !t.scheduledFor && !t.projectId).length;
  const totalDone = tasks.filter(t => t.done).length;
  const progressPct = totalPoints % 100;

  function handleAddProject() {
    const name = prompt('Project name:');
    if (!name?.trim()) return;
    const color = PROJECT_COLORS[projects.length % PROJECT_COLORS.length];
    const icons = ['📁', '🎯', '🚀', '💡', '🔥', '⭐', '🎨', '🏆'];
    const icon = icons[projects.length % icons.length];
    addProject({
      id: 'p' + Date.now(),
      name: name.trim(),
      color,
      icon,
      description: '',
      createdAt: Date.now(),
      order: projects.length,
    });
  }

  const navItem = (view: View, icon: React.ReactNode, label: string, badge?: number, projectId?: string) => {
    const active = selectedView === view && (view !== 'project' || selectedProjectId === projectId);
    return (
      <button
        key={label}
        onClick={() => setView(view, projectId)}
        className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-all ${
          active
            ? 'bg-white/15 text-white font-medium'
            : 'text-white/60 hover:bg-white/8 hover:text-white/90'
        }`}
      >
        <span className="w-4 h-4 flex-shrink-0">{icon}</span>
        <span className="flex-1 text-left">{label}</span>
        {badge !== undefined && badge > 0 && (
          <span className="text-xs bg-white/20 px-1.5 py-0.5 rounded-full">{badge}</span>
        )}
      </button>
    );
  };

  return (
    <aside className="w-60 flex-shrink-0 flex flex-col bg-black/30 border-r border-white/10 h-full overflow-y-auto">
      {/* App header */}
      <div className="px-4 py-5">
        <div className="flex items-center gap-2 mb-1">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-purple-500 to-blue-600 flex items-center justify-center text-sm">
            ✨
          </div>
          <span className="font-bold text-white text-lg">Marvin</span>
        </div>
      </div>

      {/* Level & Points */}
      <div className="mx-3 mb-4 p-3 rounded-xl bg-gradient-to-r from-purple-900/50 to-blue-900/50 border border-white/10">
        <div className="flex items-center justify-between mb-1.5">
          <span className="text-xs text-white/70">Level {level}</span>
          <span className="text-xs text-yellow-400 font-medium flex items-center gap-1">
            <Star size={10} /> {totalPoints} pts
          </span>
        </div>
        <div className="h-1.5 bg-white/10 rounded-full overflow-hidden">
          <div
            className="h-full bg-gradient-to-r from-purple-500 to-blue-500 rounded-full transition-all duration-500"
            style={{ width: `${progressPct}%` }}
          />
        </div>
        <div className="text-xs text-white/40 mt-1">{100 - progressPct} pts to level {level + 1}</div>
      </div>

      {/* Navigation */}
      <div className="px-2 space-y-0.5">
        {navItem('today', <Calendar size={16} />, 'Today', todayCount)}
        {navItem('inbox', <Inbox size={16} />, 'Inbox', inboxCount)}
        {navItem('upcoming', <CalendarDays size={16} />, 'Upcoming')}
        {navItem('done', <CheckSquare size={16} />, 'Done', totalDone)}
        {navItem('stats', <BarChart2 size={16} />, 'Stats')}
      </div>

      {/* Projects */}
      <div className="mt-4 px-2">
        <div className="flex items-center justify-between px-1 mb-1">
          <span className="text-xs font-semibold text-white/40 uppercase tracking-wider">Projects</span>
          <button
            onClick={handleAddProject}
            className="text-white/40 hover:text-white/80 transition-colors"
          >
            <Plus size={14} />
          </button>
        </div>
        <div className="space-y-0.5">
          {projects.map((project: Project) => {
            const count = tasks.filter(t => !t.done && t.projectId === project.id).length;
            const active = selectedView === 'project' && selectedProjectId === project.id;
            return (
              <button
                key={project.id}
                onClick={() => setView('project', project.id)}
                className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-all ${
                  active
                    ? 'bg-white/15 text-white font-medium'
                    : 'text-white/60 hover:bg-white/8 hover:text-white/90'
                }`}
              >
                <span
                  className="w-2 h-2 rounded-full flex-shrink-0"
                  style={{ backgroundColor: project.color }}
                />
                <span className="text-sm mr-0.5">{project.icon}</span>
                <span className="flex-1 text-left truncate">{project.name}</span>
                {count > 0 && (
                  <span className="text-xs text-white/30">{count}</span>
                )}
              </button>
            );
          })}
          <button
            onClick={() => setView('projects')}
            className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-all ${
              selectedView === 'projects'
                ? 'bg-white/15 text-white font-medium'
                : 'text-white/60 hover:bg-white/8 hover:text-white/90'
            }`}
          >
            <FolderOpen size={14} className="flex-shrink-0" />
            <span className="flex-1 text-left">All Projects</span>
          </button>
        </div>
      </div>

      <div className="flex-1" />
    </aside>
  );
}
