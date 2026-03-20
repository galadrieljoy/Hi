import { useState, useEffect, useCallback } from 'react';
import type { AppState, Task, Project, Label, View } from './types';

const STORAGE_KEY = 'marvin-app-state';

const defaultProjects: Project[] = [
  { id: 'p1', name: 'Personal', color: '#7c3aed', icon: '🏠', description: '', createdAt: Date.now(), order: 0 },
  { id: 'p2', name: 'Work', color: '#2563eb', icon: '💼', description: '', createdAt: Date.now(), order: 1 },
  { id: 'p3', name: 'Health', color: '#16a34a', icon: '💪', description: '', createdAt: Date.now(), order: 2 },
];

const defaultLabels: Label[] = [
  { id: 'l1', name: 'Important', color: '#ef4444' },
  { id: 'l2', name: 'Quick', color: '#f59e0b' },
  { id: 'l3', name: 'Waiting', color: '#6366f1' },
];

const today = new Date().toISOString().split('T')[0];

const defaultTasks: Task[] = [
  {
    id: 't1', title: 'Plan the week ahead', notes: 'Review goals and prioritize tasks',
    projectId: 'p1', labelIds: ['l2'], priority: 'high', done: false,
    scheduledFor: today, subTasks: [], timeEntries: [], points: 5,
    createdAt: Date.now(), order: 0, isStarred: true,
  },
  {
    id: 't2', title: 'Morning workout', notes: '',
    projectId: 'p3', labelIds: [], priority: 'medium', done: false,
    scheduledFor: today, subTasks: [
      { id: 'st1', title: 'Warm up 5 min', done: false },
      { id: 'st2', title: 'Cardio 20 min', done: false },
      { id: 'st3', title: 'Stretching', done: false },
    ], timeEntries: [], points: 10,
    createdAt: Date.now(), order: 1, isStarred: false,
  },
  {
    id: 't3', title: 'Review project proposal', notes: 'Check with team about timeline',
    projectId: 'p2', labelIds: ['l1'], priority: 'high', done: false,
    scheduledFor: today, subTasks: [], timeEntries: [], points: 8,
    createdAt: Date.now(), order: 2, isStarred: false,
  },
  {
    id: 't4', title: 'Buy groceries', notes: 'Milk, eggs, bread, veggies',
    projectId: 'p1', labelIds: ['l2'], priority: 'low', done: false,
    scheduledFor: undefined, subTasks: [], timeEntries: [], points: 3,
    createdAt: Date.now(), order: 3, isStarred: false,
  },
  {
    id: 't5', title: 'Read 30 pages', notes: '',
    projectId: 'p1', labelIds: [], priority: 'none', done: false,
    scheduledFor: undefined, subTasks: [], timeEntries: [], points: 4,
    createdAt: Date.now(), order: 4, isStarred: false,
  },
];

const defaultState: AppState = {
  tasks: defaultTasks,
  projects: defaultProjects,
  labels: defaultLabels,
  selectedView: 'today',
  selectedProjectId: null,
  totalPoints: 0,
  level: 1,
};

function loadState(): AppState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return { ...defaultState, ...JSON.parse(raw) };
  } catch {}
  return defaultState;
}

function saveState(state: AppState) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch {}
}

export function useAppStore() {
  const [state, setState] = useState<AppState>(loadState);

  useEffect(() => {
    saveState(state);
  }, [state]);

  const update = useCallback((updater: (s: AppState) => AppState) => {
    setState(prev => {
      const next = updater(prev);
      return next;
    });
  }, []);

  // Tasks
  const addTask = useCallback((task: Task) => {
    update(s => ({ ...s, tasks: [...s.tasks, task] }));
  }, [update]);

  const updateTask = useCallback((id: string, changes: Partial<Task>) => {
    update(s => ({
      ...s,
      tasks: s.tasks.map(t => t.id === id ? { ...t, ...changes } : t),
    }));
  }, [update]);

  const deleteTask = useCallback((id: string) => {
    update(s => ({ ...s, tasks: s.tasks.filter(t => t.id !== id) }));
  }, [update]);

  const completeTask = useCallback((id: string, done: boolean) => {
    update(s => {
      const task = s.tasks.find(t => t.id === id);
      if (!task) return s;
      const pointsDelta = done ? task.points : -task.points;
      const newTotal = Math.max(0, s.totalPoints + pointsDelta);
      const level = Math.floor(newTotal / 100) + 1;
      return {
        ...s,
        tasks: s.tasks.map(t => t.id === id ? { ...t, done, doneAt: done ? Date.now() : undefined } : t),
        totalPoints: newTotal,
        level,
      };
    });
  }, [update]);

  // Projects
  const addProject = useCallback((project: Project) => {
    update(s => ({ ...s, projects: [...s.projects, project] }));
  }, [update]);

  const updateProject = useCallback((id: string, changes: Partial<Project>) => {
    update(s => ({
      ...s,
      projects: s.projects.map(p => p.id === id ? { ...p, ...changes } : p),
    }));
  }, [update]);

  const deleteProject = useCallback((id: string) => {
    update(s => ({
      ...s,
      projects: s.projects.filter(p => p.id !== id),
      tasks: s.tasks.map(t => t.projectId === id ? { ...t, projectId: null } : t),
    }));
  }, [update]);

  // Labels
  const addLabel = useCallback((label: Label) => {
    update(s => ({ ...s, labels: [...s.labels, label] }));
  }, [update]);

  // Navigation
  const setView = useCallback((view: View, projectId?: string) => {
    update(s => ({ ...s, selectedView: view, selectedProjectId: projectId || null }));
  }, [update]);

  // Time tracking
  const startTimer = useCallback((taskId: string) => {
    update(s => ({
      ...s,
      tasks: s.tasks.map(t => {
        if (t.id !== taskId) return t;
        const lastEntry = t.timeEntries[t.timeEntries.length - 1];
        if (lastEntry && !lastEntry.end) return t; // already running
        return { ...t, timeEntries: [...t.timeEntries, { start: Date.now() }] };
      }),
    }));
  }, [update]);

  const stopTimer = useCallback((taskId: string) => {
    update(s => ({
      ...s,
      tasks: s.tasks.map(t => {
        if (t.id !== taskId) return t;
        return {
          ...t,
          timeEntries: t.timeEntries.map((e, i) =>
            i === t.timeEntries.length - 1 && !e.end ? { ...e, end: Date.now() } : e
          ),
        };
      }),
    }));
  }, [update]);

  return {
    state,
    addTask,
    updateTask,
    deleteTask,
    completeTask,
    addProject,
    updateProject,
    deleteProject,
    addLabel,
    setView,
    startTimer,
    stopTimer,
  };
}

export type AppStore = ReturnType<typeof useAppStore>;
