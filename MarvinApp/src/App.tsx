import './index.css';
import { useState } from 'react';
import { Menu } from 'lucide-react';
import { useAppStore } from './store';
import { Sidebar } from './components/Sidebar';
import { TodayView } from './components/TodayView';
import { InboxView } from './components/InboxView';
import { UpcomingView } from './components/UpcomingView';
import { ProjectView } from './components/ProjectView';
import { ProjectsView } from './components/ProjectsView';
import { DoneView } from './components/DoneView';
import { StatsView } from './components/StatsView';
import { NagSystem } from './components/NagSystem';

function App() {
  const store = useAppStore();
  const { state } = store;
  const { selectedView, selectedProjectId } = state;
  const [sidebarOpen, setSidebarOpen] = useState(false);

  function renderView() {
    switch (selectedView) {
      case 'today':    return <TodayView store={store} />;
      case 'inbox':    return <InboxView store={store} />;
      case 'upcoming': return <UpcomingView store={store} />;
      case 'projects': return <ProjectsView store={store} />;
      case 'project':  return selectedProjectId ? <ProjectView store={store} projectId={selectedProjectId} /> : <ProjectsView store={store} />;
      case 'done':     return <DoneView store={store} />;
      case 'stats':    return <StatsView store={store} />;
      default:         return <TodayView store={store} />;
    }
  }

  return (
    <div className="flex h-screen bg-[#1a1a2e] text-white overflow-hidden">
      <NagSystem store={store} />
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 md:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}
      <Sidebar store={store} isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <main className="flex-1 overflow-hidden flex flex-col min-w-0">
        <div className="md:hidden flex items-center px-4 py-3 border-b border-white/10 flex-shrink-0">
          <button
            onClick={() => setSidebarOpen(true)}
            className="text-white/60 hover:text-white"
          >
            <Menu size={22} />
          </button>
        </div>
        {renderView()}
      </main>
    </div>
  );
}

export default App;
