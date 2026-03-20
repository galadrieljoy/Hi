import { useState } from 'react';
import { Plus, ChevronDown } from 'lucide-react';
import type { AppStore } from '../store';
import type { Priority } from '../types';
import { generateId, todayString } from '../utils';

interface Props {
  store: AppStore;
  defaultProjectId?: string | null;
  scheduleToday?: boolean;
  placeholder?: string;
}

export function AddTaskBar({ store, defaultProjectId, scheduleToday, placeholder }: Props) {
  const { state, addTask } = store;
  const { projects } = state;
  const [title, setTitle] = useState('');
  const [expanded, setExpanded] = useState(false);
  const [priority, setPriority] = useState<Priority>('none');
  const [projectId, setProjectId] = useState<string | null>(defaultProjectId ?? null);

  function handleAdd() {
    if (!title.trim()) return;
    addTask({
      id: generateId(),
      title: title.trim(),
      notes: '',
      projectId,
      labelIds: [],
      priority,
      done: false,
      scheduledFor: scheduleToday ? todayString() : undefined,
      subTasks: [],
      timeEntries: [],
      points: priority === 'high' ? 8 : priority === 'medium' ? 5 : 3,
      createdAt: Date.now(),
      order: Date.now(),
      isStarred: false,
    });
    setTitle('');
  }

  return (
    <div className="bg-white/5 border border-white/10 rounded-xl overflow-hidden">
      <div className="flex items-center gap-2 px-3 py-2.5">
        <button
          onClick={handleAdd}
          className="w-5 h-5 rounded-full border-2 border-dashed border-white/30 hover:border-purple-400 flex items-center justify-center flex-shrink-0 transition-colors"
        >
          <Plus size={12} className="text-white/40" />
        </button>
        <input
          className="flex-1 bg-transparent text-sm text-white placeholder:text-white/30 outline-none"
          value={title}
          onChange={e => setTitle(e.target.value)}
          onKeyDown={e => {
            if (e.key === 'Enter') handleAdd();
            if (e.key === 'Tab' && title) { e.preventDefault(); setExpanded(true); }
          }}
          onFocus={() => title && setExpanded(true)}
          placeholder={placeholder || 'Add a task...'}
        />
        {title && (
          <button
            onClick={() => setExpanded(!expanded)}
            className="text-white/30 hover:text-white/60 transition-colors"
          >
            <ChevronDown size={14} className={`transition-transform ${expanded ? 'rotate-180' : ''}`} />
          </button>
        )}
      </div>

      {expanded && title && (
        <div className="flex items-center gap-2 px-3 pb-2.5 border-t border-white/5 pt-2">
          <select
            value={priority}
            onChange={e => setPriority(e.target.value as Priority)}
            className="flex-1 bg-white/5 border border-white/10 rounded-lg px-2 py-1 text-xs text-white/70 outline-none"
          >
            <option value="none" style={{ background: '#1e1e35' }}>No priority</option>
            <option value="low" style={{ background: '#1e1e35' }}>Low</option>
            <option value="medium" style={{ background: '#1e1e35' }}>Medium</option>
            <option value="high" style={{ background: '#1e1e35' }}>High</option>
          </select>
          <select
            value={projectId || ''}
            onChange={e => setProjectId(e.target.value || null)}
            className="flex-1 bg-white/5 border border-white/10 rounded-lg px-2 py-1 text-xs text-white/70 outline-none"
          >
            <option value="" style={{ background: '#1e1e35' }}>No project</option>
            {projects.map(p => (
              <option key={p.id} value={p.id} style={{ background: '#1e1e35' }}>{p.icon} {p.name}</option>
            ))}
          </select>
          <button
            onClick={handleAdd}
            className="bg-purple-600 hover:bg-purple-500 text-white text-xs px-3 py-1 rounded-lg font-medium transition-colors"
          >
            Add
          </button>
        </div>
      )}
    </div>
  );
}
