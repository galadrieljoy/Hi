export type Priority = 'none' | 'low' | 'medium' | 'high';

export interface Label {
  id: string;
  name: string;
  color: string;
}

export interface SubTask {
  id: string;
  title: string;
  done: boolean;
}

export interface TimeEntry {
  start: number; // timestamp
  end?: number;  // timestamp
}

export interface Task {
  id: string;
  title: string;
  notes: string;
  projectId: string | null;
  labelIds: string[];
  priority: Priority;
  done: boolean;
  doneAt?: number;
  scheduledFor?: string; // ISO date string 'YYYY-MM-DD'
  dueDate?: string;
  subTasks: SubTask[];
  timeEntries: TimeEntry[];
  points: number;
  createdAt: number;
  order: number;
  isStarred: boolean;
  plannedTime?: string; // 'HH:MM' - the time user commits to doing this task today
}

export interface Project {
  id: string;
  name: string;
  color: string;
  icon: string;
  description: string;
  createdAt: number;
  order: number;
}

export type View = 'today' | 'inbox' | 'upcoming' | 'projects' | 'project' | 'done' | 'stats';

export interface AppState {
  tasks: Task[];
  projects: Project[];
  labels: Label[];
  selectedView: View;
  selectedProjectId: string | null;
  totalPoints: number;
  level: number;
}
