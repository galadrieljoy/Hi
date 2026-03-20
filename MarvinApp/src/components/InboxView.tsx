import { Inbox, Filter } from 'lucide-react';
import { useState } from 'react';
import type { AppStore } from '../store';
import { TaskCard } from './TaskCard';
import { AddTaskBar } from './AddTaskBar';
import type { Priority } from '../types';

interface Props {
  store: AppStore;
}

export function InboxView({ store }: Props) {
  const { state } = store;
  const { tasks, projects } = state;
  const [filterPriority, setFilterPriority] = useState<Priority | 'all'>('all');
  const [filterProject, setFilterProject] = useState<string>('all');

  const inboxTasks = tasks.filter(t => {
    if (t.done) return false;
    let match = true;
    if (filterPriority !== 'all') match = match && t.priority === filterPriority;
    if (filterProject !== 'all') match = match && t.projectId === filterProject;
    return match;
  });

  // Group by project
  const grouped = new Map<string, typeof inboxTasks>();
  inboxTasks.forEach(task => {
    const key = task.projectId || '__none__';
    if (!grouped.has(key)) grouped.set(key, []);
    grouped.get(key)!.push(task);
  });

  return (
    <div className="flex-1 overflow-y-auto p-6">
      <div className="max-w-2xl mx-auto space-y-6">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <Inbox size={20} className="text-blue-400" />
            <h1 className="text-2xl font-bold text-white">Inbox</h1>
          </div>
          <p className="text-white/40 text-sm">{inboxTasks.length} tasks not scheduled</p>
        </div>

        {/* Filters */}
        <div className="flex items-center gap-2 flex-wrap">
          <Filter size={14} className="text-white/30" />
          <select
            value={filterPriority}
            onChange={e => setFilterPriority(e.target.value as any)}
            className="bg-white/5 border border-white/10 rounded-lg px-2 py-1 text-xs text-white/60 outline-none"
          >
            <option value="all" style={{ background: '#1a1a2e' }}>All priorities</option>
            <option value="high" style={{ background: '#1a1a2e' }}>High</option>
            <option value="medium" style={{ background: '#1a1a2e' }}>Medium</option>
            <option value="low" style={{ background: '#1a1a2e' }}>Low</option>
            <option value="none" style={{ background: '#1a1a2e' }}>No priority</option>
          </select>
          <select
            value={filterProject}
            onChange={e => setFilterProject(e.target.value)}
            className="bg-white/5 border border-white/10 rounded-lg px-2 py-1 text-xs text-white/60 outline-none"
          >
            <option value="all" style={{ background: '#1a1a2e' }}>All projects</option>
            <option value="__none__" style={{ background: '#1a1a2e' }}>No project</option>
            {projects.map(p => (
              <option key={p.id} value={p.id} style={{ background: '#1a1a2e' }}>{p.name}</option>
            ))}
          </select>
        </div>

        {/* Task groups */}
        {Array.from(grouped.entries()).map(([key, groupTasks]) => {
          const project = key === '__none__' ? null : projects.find(p => p.id === key);
          return (
            <div key={key}>
              <div className="flex items-center gap-2 mb-2">
                {project ? (
                  <>
                    <span className="w-2 h-2 rounded-full" style={{ backgroundColor: project.color }} />
                    <span className="text-sm font-medium text-white/60">{project.icon} {project.name}</span>
                  </>
                ) : (
                  <span className="text-sm font-medium text-white/40">No project</span>
                )}
                <span className="text-xs text-white/25">({groupTasks.length})</span>
              </div>
              <div className="space-y-2">
                {groupTasks.map(task => (
                  <TaskCard key={task.id} task={task} store={store} />
                ))}
              </div>
            </div>
          );
        })}

        <AddTaskBar store={store} placeholder="Add to inbox..." />

        {inboxTasks.length === 0 && (
          <div className="text-center py-16 text-white/20">
            <div className="text-5xl mb-4">📬</div>
            <div className="text-lg font-medium mb-1">Inbox is empty!</div>
            <div className="text-sm">All tasks are scheduled or completed</div>
          </div>
        )}
      </div>
    </div>
  );
}
