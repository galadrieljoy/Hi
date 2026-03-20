import { useState } from 'react';
import { X, Plus, Trash2, Clock, Star } from 'lucide-react';
import type { Task, Priority } from '../types';
import type { AppStore } from '../store';
import { generateId, getTotalTime, formatDuration, isTimerRunning } from '../utils';

interface Props {
  task: Task;
  store: AppStore;
  onClose: () => void;
}

export function TaskModal({ task, store, onClose }: Props) {
  const { state, updateTask, deleteTask, startTimer, stopTimer } = store;
  const { projects, labels } = state;

  const [title, setTitle] = useState(task.title);
  const [notes, setNotes] = useState(task.notes);
  const [priority, setPriority] = useState<Priority>(task.priority);
  const [projectId, setProjectId] = useState(task.projectId);
  const [selectedLabels, setSelectedLabels] = useState<string[]>(task.labelIds);
  const [dueDate, setDueDate] = useState(task.dueDate || '');
  const [plannedTime, setPlannedTime] = useState(task.plannedTime || '');
  const [newSubtask, setNewSubtask] = useState('');
  const [points, setPoints] = useState(task.points);

  const timerRunning = isTimerRunning(task);
  const totalTime = getTotalTime(task.timeEntries);

  function save() {
    updateTask(task.id, {
      title,
      notes,
      priority,
      projectId,
      labelIds: selectedLabels,
      dueDate: dueDate || undefined,
      plannedTime: plannedTime || undefined,
      points,
    });
    onClose();
  }

  function addSubtask() {
    if (!newSubtask.trim()) return;
    updateTask(task.id, {
      subTasks: [...task.subTasks, { id: generateId(), title: newSubtask.trim(), done: false }],
    });
    setNewSubtask('');
  }

  function toggleSubtask(id: string) {
    updateTask(task.id, {
      subTasks: task.subTasks.map(s => s.id === id ? { ...s, done: !s.done } : s),
    });
  }

  function removeSubtask(id: string) {
    updateTask(task.id, {
      subTasks: task.subTasks.filter(s => s.id !== id),
    });
  }

  function toggleLabel(id: string) {
    setSelectedLabels(prev =>
      prev.includes(id) ? prev.filter(l => l !== id) : [...prev, id]
    );
  }

  function handleDelete() {
    if (confirm('Delete this task?')) {
      deleteTask(task.id);
      onClose();
    }
  }

  const priorityOptions: Priority[] = ['none', 'low', 'medium', 'high'];

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
      <div className="bg-[#1e1e35] border border-white/10 rounded-2xl w-full max-w-xl shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-white/10">
          <div className="flex items-center gap-2">
            <button
              onClick={() => updateTask(task.id, { isStarred: !task.isStarred })}
              className={`transition-colors ${task.isStarred ? 'text-yellow-400' : 'text-white/30 hover:text-yellow-400'}`}
            >
              <Star size={16} fill={task.isStarred ? 'currentColor' : 'none'} />
            </button>
            <span className="text-sm text-white/40">Edit Task</span>
          </div>
          <div className="flex items-center gap-2">
            <button onClick={handleDelete} className="text-white/30 hover:text-red-400 transition-colors">
              <Trash2 size={16} />
            </button>
            <button onClick={onClose} className="text-white/30 hover:text-white transition-colors">
              <X size={18} />
            </button>
          </div>
        </div>

        <div className="p-4 space-y-4 max-h-[70vh] overflow-y-auto">
          {/* Title */}
          <input
            className="w-full bg-transparent text-white text-lg font-medium border-none outline-none placeholder:text-white/30"
            value={title}
            onChange={e => setTitle(e.target.value)}
            placeholder="Task title..."
          />

          {/* Notes */}
          <textarea
            className="w-full bg-white/5 rounded-lg px-3 py-2 text-sm text-white/80 placeholder:text-white/30 border border-white/10 focus:outline-none focus:border-white/30 resize-none"
            rows={3}
            value={notes}
            onChange={e => setNotes(e.target.value)}
            placeholder="Add notes..."
          />

          {/* Priority & Project row */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs text-white/40 mb-1 block">Priority</label>
              <select
                value={priority}
                onChange={e => setPriority(e.target.value as Priority)}
                className="w-full bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-sm text-white outline-none"
              >
                {priorityOptions.map(p => (
                  <option key={p} value={p} style={{ background: '#1e1e35' }}>
                    {p === 'none' ? 'No priority' : p.charAt(0).toUpperCase() + p.slice(1)}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="text-xs text-white/40 mb-1 block">Project</label>
              <select
                value={projectId || ''}
                onChange={e => setProjectId(e.target.value || null)}
                className="w-full bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-sm text-white outline-none"
              >
                <option value="" style={{ background: '#1e1e35' }}>No project</option>
                {projects.map(p => (
                  <option key={p.id} value={p.id} style={{ background: '#1e1e35' }}>{p.icon} {p.name}</option>
                ))}
              </select>
            </div>
          </div>

          {/* Due date & Points row */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs text-white/40 mb-1 block">Due date</label>
              <input
                type="date"
                value={dueDate}
                onChange={e => setDueDate(e.target.value)}
                className="w-full bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-sm text-white outline-none"
              />
            </div>
            <div>
              <label className="text-xs text-white/40 mb-1 block">Points reward</label>
              <input
                type="number"
                value={points}
                onChange={e => setPoints(Math.max(1, parseInt(e.target.value) || 1))}
                min={1}
                max={100}
                className="w-full bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-sm text-white outline-none"
              />
            </div>
          </div>

          {/* Planned time (nag) */}
          <div>
            <label className="text-xs text-orange-400/80 mb-1 block">⏰ I'll do this by... (starts nagging if missed)</label>
            <div className="flex gap-2 items-center">
              <input
                type="time"
                value={plannedTime}
                onChange={e => setPlannedTime(e.target.value)}
                className="bg-white/5 border border-orange-400/30 rounded-lg px-3 py-2 text-sm text-white outline-none focus:border-orange-400/60"
              />
              {plannedTime && (
                <button
                  onClick={() => setPlannedTime('')}
                  className="text-xs text-white/30 hover:text-white/60 transition-colors"
                >
                  Clear
                </button>
              )}
              {!plannedTime && (
                <span className="text-xs text-white/30">Optional — set a commitment time</span>
              )}
            </div>
          </div>

          {/* Labels */}
          <div>
            <label className="text-xs text-white/40 mb-2 block">Labels</label>
            <div className="flex flex-wrap gap-2">
              {labels.map(label => (
                <button
                  key={label.id}
                  onClick={() => toggleLabel(label.id)}
                  className={`px-2.5 py-1 rounded-full text-xs font-medium transition-all ${
                    selectedLabels.includes(label.id)
                      ? 'text-white'
                      : 'text-white/40 border border-white/20 hover:text-white/70'
                  }`}
                  style={selectedLabels.includes(label.id) ? { backgroundColor: label.color } : {}}
                >
                  {label.name}
                </button>
              ))}
            </div>
          </div>

          {/* Subtasks */}
          <div>
            <label className="text-xs text-white/40 mb-2 block">Subtasks ({task.subTasks.filter(s => s.done).length}/{task.subTasks.length})</label>
            <div className="space-y-1 mb-2">
              {task.subTasks.map(sub => (
                <div key={sub.id} className="flex items-center gap-2 group">
                  <button
                    onClick={() => toggleSubtask(sub.id)}
                    className={`w-4 h-4 rounded border flex-shrink-0 flex items-center justify-center transition-all ${
                      sub.done ? 'bg-purple-500 border-purple-500' : 'border-white/30'
                    }`}
                  >
                    {sub.done && <span className="text-white text-xs">✓</span>}
                  </button>
                  <span className={`flex-1 text-sm ${sub.done ? 'line-through text-white/30' : 'text-white/80'}`}>
                    {sub.title}
                  </span>
                  <button
                    onClick={() => removeSubtask(sub.id)}
                    className="opacity-0 group-hover:opacity-100 text-white/30 hover:text-red-400 transition-all"
                  >
                    <X size={12} />
                  </button>
                </div>
              ))}
            </div>
            <div className="flex gap-2">
              <input
                className="flex-1 bg-white/5 border border-white/10 rounded-lg px-3 py-1.5 text-sm text-white placeholder:text-white/30 outline-none focus:border-white/30"
                value={newSubtask}
                onChange={e => setNewSubtask(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && addSubtask()}
                placeholder="Add subtask..."
              />
              <button
                onClick={addSubtask}
                className="bg-white/10 hover:bg-white/20 rounded-lg px-3 text-white/70 transition-colors"
              >
                <Plus size={14} />
              </button>
            </div>
          </div>

          {/* Timer */}
          <div className="flex items-center justify-between p-3 bg-white/5 rounded-xl border border-white/10">
            <div className="flex items-center gap-2 text-sm text-white/60">
              <Clock size={14} />
              <span>Time tracked: {formatDuration(timerRunning ? getTotalTime(task.timeEntries) : totalTime)}</span>
            </div>
            <button
              onClick={() => timerRunning ? stopTimer(task.id) : startTimer(task.id)}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                timerRunning
                  ? 'bg-red-500/20 text-red-400 hover:bg-red-500/30'
                  : 'bg-green-500/20 text-green-400 hover:bg-green-500/30'
              }`}
            >
              {timerRunning ? '⏹ Stop' : '▶ Start'}
            </button>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-white/10 flex justify-end gap-3">
          <button onClick={onClose} className="px-4 py-2 rounded-lg text-sm text-white/50 hover:text-white transition-colors">
            Cancel
          </button>
          <button
            onClick={save}
            className="px-4 py-2 rounded-lg text-sm bg-purple-600 hover:bg-purple-500 text-white font-medium transition-colors"
          >
            Save
          </button>
        </div>
      </div>
    </div>
  );
}
