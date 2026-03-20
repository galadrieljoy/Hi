import './index.css';
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
      <Sidebar store={store} />
      <main className="flex-1 overflow-hidden flex flex-col">
        {renderView()}
      </main>
    </div>
  );
}

export default App;
