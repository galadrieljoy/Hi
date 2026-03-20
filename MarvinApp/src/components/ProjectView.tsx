import { useState } from 'react';
import { Edit2, Trash2, Check } from 'lucide-react';
import type { AppStore } from '../store';
import { TaskCard } from './TaskCard';
import { AddTaskBar } from './AddTaskBar';

interface Props {
  store: AppStore;
  projectId: string;
}

export function ProjectView({ store, projectId }: Props) {
  const { state, updateProject, deleteProject, setView } = store;
  const { tasks, projects } = state;

  const project = projects.find(p => p.id === projectId);
  const [editName, setEditName] = useState(false);
  const [nameInput, setNameInput] = useState(project?.name || '');

  if (!project) return (
    <div className="flex-1 flex items-center justify-center text-white/30">
      Project not found
    </div>
  );

  const projectTasks = tasks.filter(t => t.projectId === projectId && !t.done);
  const doneTasks = tasks.filter(t => t.projectId === projectId && t.done);
  const completionRate = tasks.filter(t => t.projectId === projectId).length > 0
    ? Math.round((doneTasks.length / tasks.filter(t => t.projectId === projectId).length) * 100)
    : 0;

  function saveName() {
    if (nameInput.trim()) updateProject(projectId, { name: nameInput.trim() });
    setEditName(false);
  }

  function handleDelete() {
    if (confirm(`Delete project "${project?.name}"? Tasks will keep their data.`)) {
      deleteProject(projectId);
      setView('projects');
    }
  }

  return (
    <div className="flex-1 overflow-y-auto p-6">
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Header */}
        <div>
          <div className="flex items-center gap-3 mb-2">
            <span className="text-3xl">{project.icon}</span>
            {editName ? (
              <div className="flex items-center gap-2 flex-1">
                <input
                  className="flex-1 bg-transparent text-2xl font-bold text-white border-b border-white/30 outline-none"
                  value={nameInput}
                  onChange={e => setNameInput(e.target.value)}
                  onKeyDown={e => { if (e.key === 'Enter') saveName(); if (e.key === 'Escape') setEditName(false); }}
                  autoFocus
                />
                <button onClick={saveName} className="text-green-400"><Check size={18} /></button>
              </div>
            ) : (
              <div className="flex items-center gap-2 flex-1">
                <h1 className="text-2xl font-bold text-white">{project.name}</h1>
                <button onClick={() => setEditName(true)} className="text-white/30 hover:text-white/60 transition-colors">
                  <Edit2 size={14} />
                </button>
              </div>
            )}
            <button onClick={handleDelete} className="text-white/20 hover:text-red-400 transition-colors">
              <Trash2 size={16} />
            </button>
          </div>

          {/* Stats */}
          <div className="flex items-center gap-4 text-sm text-white/40">
            <span>{projectTasks.length} remaining</span>
            <span>{doneTasks.length} done</span>
            <span>{completionRate}% complete</span>
          </div>

          {/* Progress bar */}
          <div className="mt-3 h-2 bg-white/10 rounded-full overflow-hidden">
            <div
              className="h-full rounded-full transition-all duration-500"
              style={{ width: `${completionRate}%`, backgroundColor: project.color }}
            />
          </div>
        </div>

        {/* Tasks */}
        <div className="space-y-2">
          {projectTasks.map(task => (
            <TaskCard key={task.id} task={task} store={store} />
          ))}
        </div>

        <AddTaskBar store={store} defaultProjectId={projectId} placeholder={`Add task to ${project.name}...`} />

        {/* Done tasks */}
        {doneTasks.length > 0 && (
          <div>
            <div className="text-sm font-semibold text-white/30 mb-3">Completed ({doneTasks.length})</div>
            <div className="space-y-1.5">
              {doneTasks.slice(0, 10).map(task => (
                <TaskCard key={task.id} task={task} store={store} />
              ))}
            </div>
          </div>
        )}

        {projectTasks.length === 0 && doneTasks.length === 0 && (
          <div className="text-center py-16 text-white/20">
            <div className="text-5xl mb-4">{project.icon}</div>
            <div className="text-lg font-medium mb-1">No tasks yet</div>
            <div className="text-sm">Add tasks to get started</div>
          </div>
        )}
      </div>
    </div>
  );
}
