import { useState } from 'react';
import { Clock, Star, Timer, CalendarPlus } from 'lucide-react';
import type { Task } from '../types';
import type { AppStore } from '../store';
import { TaskModal } from './TaskModal';
import { isTimerRunning, getTotalTime, formatDuration, getPriorityColor, todayString, formatDate } from '../utils';

interface Props {
  task: Task;
  store: AppStore;
  showProject?: boolean;
}

export function TaskCard({ task, store, showProject = false }: Props) {
  const { state, completeTask, updateTask, startTimer, stopTimer } = store;
  const { projects, labels } = state;
  const [showModal, setShowModal] = useState(false);

  const project = projects.find(p => p.id === task.projectId);
  const taskLabels = labels.filter(l => task.labelIds.includes(l.id));
  const timerRunning = isTimerRunning(task);
  const totalTime = getTotalTime(task.timeEntries);
  const subtasksDone = task.subTasks.filter(s => s.done).length;
  const isToday = task.scheduledFor === todayString();

  function scheduleToday() {
    updateTask(task.id, { scheduledFor: todayString() });
  }

  function removeFromToday() {
    updateTask(task.id, { scheduledFor: undefined });
  }

  const priorityColor = getPriorityColor(task.priority);

  return (
    <>
      <div
        className={`group flex items-start gap-3 p-3 rounded-xl border transition-all cursor-pointer ${
          task.done
            ? 'bg-white/3 border-white/5 opacity-50'
            : 'bg-white/5 border-white/10 hover:bg-white/8 hover:border-white/20'
        }`}
        onClick={() => setShowModal(true)}
      >
        {/* Priority indicator */}
        <div
          className="w-0.5 self-stretch rounded-full flex-shrink-0 mt-1"
          style={{ backgroundColor: priorityColor, minWidth: '2px', opacity: task.priority === 'none' ? 0.1 : 1 }}
        />

        {/* Checkbox */}
        <button
          onClick={e => { e.stopPropagation(); completeTask(task.id, !task.done); }}
          className={`w-5 h-5 rounded-full border-2 flex-shrink-0 mt-0.5 flex items-center justify-center transition-all ${
            task.done
              ? 'bg-purple-500 border-purple-500'
              : 'border-white/30 hover:border-purple-400'
          }`}
        >
          {task.done && <span className="text-white text-xs">✓</span>}
        </button>

        {/* Content */}
        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2">
            <span className={`text-sm leading-snug ${task.done ? 'line-through text-white/30' : 'text-white/90'}`}>
              {task.title}
            </span>
            <div className="flex items-center gap-1.5 flex-shrink-0">
              {task.isStarred && <Star size={12} className="text-yellow-400" fill="currentColor" />}
              {timerRunning && (
                <span className="flex items-center gap-1 text-xs text-green-400 animate-pulse">
                  <Timer size={10} /> Live
                </span>
              )}
            </div>
          </div>

          {/* Meta row */}
          <div className="flex items-center flex-wrap gap-2 mt-1.5">
            {showProject && project && (
              <span
                className="text-xs px-1.5 py-0.5 rounded-md font-medium"
                style={{ backgroundColor: project.color + '30', color: project.color }}
              >
                {project.icon} {project.name}
              </span>
            )}
            {taskLabels.map(label => (
              <span
                key={label.id}
                className="text-xs px-1.5 py-0.5 rounded-full"
                style={{ backgroundColor: label.color + '25', color: label.color }}
              >
                {label.name}
              </span>
            ))}
            {task.subTasks.length > 0 && (
              <span className="text-xs text-white/40">
                {subtasksDone}/{task.subTasks.length} subtasks
              </span>
            )}
            {totalTime > 0 && (
              <span className="flex items-center gap-1 text-xs text-white/40">
                <Clock size={10} /> {formatDuration(totalTime)}
              </span>
            )}
            {task.dueDate && (
              <span className="text-xs text-white/40">
                Due {formatDate(task.dueDate)}
              </span>
            )}
            {task.scheduledFor && !isToday && task.scheduledFor !== todayString() && (
              <span className="text-xs text-blue-400">
                {formatDate(task.scheduledFor)}
              </span>
            )}
          </div>

          {/* Subtask progress */}
          {task.subTasks.length > 0 && (
            <div className="mt-2 h-1 bg-white/10 rounded-full overflow-hidden">
              <div
                className="h-full bg-purple-500 rounded-full transition-all"
                style={{ width: `${(subtasksDone / task.subTasks.length) * 100}%` }}
              />
            </div>
          )}
        </div>

        {/* Right actions */}
        <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0">
          {!task.done && (
            <>
              {isToday ? (
                <button
                  onClick={e => { e.stopPropagation(); removeFromToday(); }}
                  className="text-xs text-white/30 hover:text-white/60 px-1.5 py-1 rounded transition-colors"
                  title="Remove from today"
                >
                  −Today
                </button>
              ) : (
                <button
                  onClick={e => { e.stopPropagation(); scheduleToday(); }}
                  className="text-xs text-purple-400 hover:text-purple-300 px-1.5 py-1 rounded transition-colors flex items-center gap-1"
                  title="Schedule for today"
                >
                  <CalendarPlus size={12} />
                </button>
              )}
              <button
                onClick={e => {
                  e.stopPropagation();
                  timerRunning ? stopTimer(task.id) : startTimer(task.id);
                }}
                className={`text-xs px-1.5 py-1 rounded transition-colors ${
                  timerRunning ? 'text-red-400 hover:text-red-300' : 'text-white/30 hover:text-green-400'
                }`}
                title={timerRunning ? 'Stop timer' : 'Start timer'}
              >
                {timerRunning ? '⏹' : '▶'}
              </button>
            </>
          )}
          <span className="text-yellow-500/60 text-xs">+{task.points}</span>
        </div>
      </div>

      {showModal && (
        <TaskModal task={task} store={store} onClose={() => setShowModal(false)} />
      )}
    </>
  );
}
