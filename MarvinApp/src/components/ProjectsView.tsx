import { Plus, FolderOpen } from 'lucide-react';
import type { AppStore } from '../store';

interface Props {
  store: AppStore;
}

const PROJECT_COLORS = [
  '#7c3aed', '#2563eb', '#16a34a', '#dc2626', '#d97706',
  '#db2777', '#0891b2', '#65a30d', '#ea580c', '#0d9488',
];

export function ProjectsView({ store }: Props) {
  const { state, setView, addProject } = store;
  const { projects, tasks } = state;

  function handleAddProject() {
    const name = prompt('Project name:');
    if (!name?.trim()) return;
    const color = PROJECT_COLORS[projects.length % PROJECT_COLORS.length];
    const icons = ['📁', '🎯', '🚀', '💡', '🔥', '⭐', '🎨', '🏆', '🌟', '💎'];
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

  return (
    <div className="flex-1 overflow-y-auto p-6">
      <div className="max-w-3xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <FolderOpen size={20} className="text-orange-400" />
              <h1 className="text-2xl font-bold text-white">Projects</h1>
            </div>
            <p className="text-white/40 text-sm">{projects.length} projects</p>
          </div>
          <button
            onClick={handleAddProject}
            className="flex items-center gap-2 bg-purple-600 hover:bg-purple-500 text-white px-4 py-2 rounded-xl text-sm font-medium transition-colors"
          >
            <Plus size={16} />
            New Project
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {projects.map(project => {
            const totalTasks = tasks.filter(t => t.projectId === project.id);
            const doneTasks = totalTasks.filter(t => t.done);
            const remaining = totalTasks.length - doneTasks.length;
            const pct = totalTasks.length > 0 ? Math.round((doneTasks.length / totalTasks.length) * 100) : 0;

            return (
              <button
                key={project.id}
                onClick={() => setView('project', project.id)}
                className="text-left bg-white/5 hover:bg-white/8 border border-white/10 hover:border-white/20 rounded-2xl p-5 transition-all group"
              >
                <div className="flex items-start justify-between mb-4">
                  <span className="text-3xl">{project.icon}</span>
                  <span className="text-xs text-white/30">{remaining} left</span>
                </div>
                <div className="font-semibold text-white mb-1">{project.name}</div>
                <div className="text-xs text-white/40 mb-3">{totalTasks.length} total tasks</div>
                <div className="h-1.5 bg-white/10 rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all"
                    style={{ width: `${pct}%`, backgroundColor: project.color }}
                  />
                </div>
                <div className="text-xs text-white/30 mt-1.5">{pct}% complete</div>
              </button>
            );
          })}

          <button
            onClick={handleAddProject}
            className="text-left bg-white/3 hover:bg-white/5 border border-dashed border-white/10 hover:border-white/20 rounded-2xl p-5 transition-all flex flex-col items-center justify-center gap-2 text-white/30 hover:text-white/50 min-h-[140px]"
          >
            <Plus size={24} />
            <span className="text-sm font-medium">New Project</span>
          </button>
        </div>
      </div>
    </div>
  );
}
