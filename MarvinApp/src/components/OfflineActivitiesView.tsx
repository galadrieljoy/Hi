import { useState } from 'react';
import { Shuffle, Plus, Trash2, Zap } from 'lucide-react';

const DEFAULT_ACTIVITIES = [
  'Take a 10-minute walk outside',
  'Do 10 push-ups or squats',
  'Stretch for 5 minutes',
  'Drink a full glass of water',
  'Tidy up one small area of your space',
  'Do some deep breathing (4-7-8 method)',
  'Journal for 5 minutes',
  'Water a plant',
  'Make a cup of tea or coffee',
  'Do a quick doodle or sketch',
  'Fold laundry or put it away',
  'Do 1 minute of jumping jacks',
  'Step outside and get some fresh air',
  'Read a physical book for 10 minutes',
  'Write down 3 things you\'re grateful for',
  'Do some light yoga or stretching',
  'Wash your face with cold water',
  'Organize one drawer or shelf',
  'Play with a pet',
  'Hum or sing a song to yourself',
];

const SPIN_FRAMES = ['🎲', '🎯', '✨', '🌀', '⚡', '🎲'];

export function OfflineActivitiesView() {
  const [activities, setActivities] = useState<string[]>(() => {
    try {
      const saved = localStorage.getItem('offline-activities');
      return saved ? JSON.parse(saved) : DEFAULT_ACTIVITIES;
    } catch {
      return DEFAULT_ACTIVITIES;
    }
  });
  const [picked, setPicked] = useState<string | null>(null);
  const [spinning, setSpinning] = useState(false);
  const [spinFrame, setSpinFrame] = useState(0);
  const [newActivity, setNewActivity] = useState('');
  const [showList, setShowList] = useState(false);

  function saveActivities(list: string[]) {
    setActivities(list);
    localStorage.setItem('offline-activities', JSON.stringify(list));
  }

  function pickRandom() {
    if (activities.length === 0) return;
    setSpinning(true);
    setPicked(null);

    let frame = 0;
    const interval = setInterval(() => {
      setSpinFrame(frame % SPIN_FRAMES.length);
      frame++;
    }, 80);

    setTimeout(() => {
      clearInterval(interval);
      setSpinning(false);
      const idx = Math.floor(Math.random() * activities.length);
      setPicked(activities[idx]);
    }, 1200);
  }

  function addActivity() {
    const trimmed = newActivity.trim();
    if (!trimmed) return;
    saveActivities([...activities, trimmed]);
    setNewActivity('');
  }

  function removeActivity(index: number) {
    const updated = activities.filter((_, i) => i !== index);
    saveActivities(updated);
    if (picked && activities[index] === picked) setPicked(null);
  }

  function resetToDefaults() {
    saveActivities(DEFAULT_ACTIVITIES);
    setPicked(null);
  }

  return (
    <div className="flex-1 flex flex-col max-w-lg mx-auto w-full p-6 gap-6">
      {/* Header */}
      <div>
        <h2 className="text-2xl font-bold text-white">Offline Activity Picker</h2>
        <p className="text-white/40 text-sm mt-1">Step away from the screen — pick something random to do.</p>
      </div>

      {/* Big Pick Button */}
      <div className="flex flex-col items-center gap-4">
        <button
          onClick={pickRandom}
          disabled={spinning || activities.length === 0}
          className="w-full py-5 rounded-2xl bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-500 hover:to-blue-500
            disabled:opacity-50 disabled:cursor-not-allowed text-white font-bold text-xl
            flex items-center justify-center gap-3 transition-all active:scale-95 shadow-lg shadow-purple-900/30"
        >
          {spinning ? (
            <>
              <span className="text-3xl animate-spin">{SPIN_FRAMES[spinFrame]}</span>
              Picking...
            </>
          ) : (
            <>
              <Shuffle size={24} />
              Pick a random activity
            </>
          )}
        </button>

        {/* Result */}
        {picked && !spinning && (
          <div className="w-full p-5 rounded-2xl bg-gradient-to-br from-purple-900/60 to-blue-900/60 border border-white/20 text-center">
            <div className="text-4xl mb-3">
              <Zap className="inline text-yellow-400" size={36} />
            </div>
            <p className="text-white font-semibold text-lg leading-snug">{picked}</p>
            <button
              onClick={pickRandom}
              className="mt-4 text-white/50 hover:text-white/80 text-sm underline underline-offset-2 transition-colors"
            >
              Not feeling it — pick another
            </button>
          </div>
        )}
      </div>

      {/* Activity List Toggle */}
      <div>
        <button
          onClick={() => setShowList(v => !v)}
          className="text-white/50 hover:text-white/80 text-sm transition-colors flex items-center gap-1.5"
        >
          <span>{showList ? '▾' : '▸'}</span>
          {showList ? 'Hide' : 'Edit'} activity list ({activities.length})
        </button>

        {showList && (
          <div className="mt-3 space-y-2">
            {/* Add new */}
            <div className="flex gap-2">
              <input
                type="text"
                value={newActivity}
                onChange={e => setNewActivity(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && addActivity()}
                placeholder="Add an activity..."
                className="flex-1 bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-white text-sm placeholder-white/30 focus:outline-none focus:border-purple-500"
              />
              <button
                onClick={addActivity}
                disabled={!newActivity.trim()}
                className="px-3 py-2 rounded-lg bg-purple-600 hover:bg-purple-500 disabled:opacity-40 text-white transition-colors"
              >
                <Plus size={16} />
              </button>
            </div>

            {/* List */}
            <div className="space-y-1 max-h-72 overflow-y-auto pr-1">
              {activities.map((activity, i) => (
                <div
                  key={i}
                  className="flex items-center gap-2 px-3 py-2 rounded-lg bg-white/5 hover:bg-white/8 group"
                >
                  <span className="flex-1 text-white/80 text-sm">{activity}</span>
                  <button
                    onClick={() => removeActivity(i)}
                    className="text-white/20 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-all"
                  >
                    <Trash2 size={14} />
                  </button>
                </div>
              ))}
            </div>

            <button
              onClick={resetToDefaults}
              className="text-white/30 hover:text-white/60 text-xs transition-colors"
            >
              Reset to defaults
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
