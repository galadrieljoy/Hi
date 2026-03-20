import './index.css';
import { useState, useEffect } from 'react';
import { Menu, LogOut, Cloud } from 'lucide-react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from './lib/supabase';
import { useAppStore } from './store';
import { AuthPage } from './components/AuthPage';
import { Sidebar } from './components/Sidebar';
import { TodayView } from './components/TodayView';
import { InboxView } from './components/InboxView';
import { UpcomingView } from './components/UpcomingView';
import { ProjectView } from './components/ProjectView';
import { ProjectsView } from './components/ProjectsView';
import { DoneView } from './components/DoneView';
import { StatsView } from './components/StatsView';
import { LightCastView } from './components/LightCastView';
import { OfflineActivitiesView } from './components/OfflineActivitiesView';
import { NagSystem } from './components/NagSystem';

function MainApp({ userId, userEmail }: { userId: string; userEmail: string }) {
  const store = useAppStore(userId);
  const { state, cloudSyncing } = store;
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
      case 'stats':      return <StatsView store={store} />;
      case 'lightcast':   return <LightCastView />;
      case 'activities':  return <OfflineActivitiesView />;
      default:            return <TodayView store={store} />;
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
        <div className="flex items-center px-4 py-3 border-b border-white/10 flex-shrink-0">
          <button
            onClick={() => setSidebarOpen(true)}
            className="text-white/60 hover:text-white md:hidden"
          >
            <Menu size={22} />
          </button>
          <div className="flex-1" />
          <div className="flex items-center gap-3">
            {cloudSyncing && (
              <span className="flex items-center gap-1 text-xs text-white/40">
                <Cloud size={13} />
                Syncing...
              </span>
            )}
            <span className="text-xs text-white/40 hidden sm:block">{userEmail}</span>
            <button
              onClick={() => supabase.auth.signOut()}
              className="flex items-center gap-1.5 text-xs text-white/40 hover:text-white/70 transition-colors"
              title="Log out"
            >
              <LogOut size={14} />
              <span className="hidden sm:block">Log out</span>
            </button>
          </div>
        </div>
        {renderView()}
      </main>
    </div>
  );
}

function App() {
  const [session, setSession] = useState<Session | null | undefined>(undefined);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setSession(data.session));
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });
    return () => subscription.unsubscribe();
  }, []);

  if (session === undefined) {
    return (
      <div className="min-h-screen bg-[#1a1a2e] flex items-center justify-center">
        <div className="text-white/30 text-sm">Loading...</div>
      </div>
    );
  }

  if (!session) return <AuthPage />;

  return <MainApp userId={session.user.id} userEmail={session.user.email ?? ''} />;
}

export default App;
