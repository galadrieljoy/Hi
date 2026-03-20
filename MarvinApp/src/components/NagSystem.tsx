import { useEffect, useState, useRef, useCallback } from 'react';
import type { Task } from '../types';
import type { AppStore } from '../store';
import { todayString } from '../utils';

// --- Sound generation ---
function playAlarm(level: number) {
  try {
    const ctx = new AudioContext();

    if (level >= 5) {
      // Level 5: chaotic multi-tone shriek
      const freqs = [880, 1200, 660, 1500, 440, 1760];
      freqs.forEach((freq, i) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(freq, ctx.currentTime + i * 0.08);
        osc.frequency.exponentialRampToValueAtTime(freq * 1.5, ctx.currentTime + i * 0.08 + 0.1);
        gain.gain.setValueAtTime(0.4, ctx.currentTime + i * 0.08);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + i * 0.08 + 0.3);
        osc.start(ctx.currentTime + i * 0.08);
        osc.stop(ctx.currentTime + i * 0.08 + 0.35);
      });
    } else if (level === 4) {
      // Level 4: urgent double beep
      [0, 0.25].forEach(offset => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.type = 'square';
        osc.frequency.value = 900;
        gain.gain.setValueAtTime(0.3, ctx.currentTime + offset);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + offset + 0.2);
        osc.start(ctx.currentTime + offset);
        osc.stop(ctx.currentTime + offset + 0.22);
      });
    } else if (level === 3) {
      // Level 3: single sharp beep
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.type = 'sine';
      osc.frequency.value = 750;
      gain.gain.setValueAtTime(0.25, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.3);
      osc.start(ctx.currentTime);
      osc.stop(ctx.currentTime + 0.32);
    }
    // Levels 1-2: no sound, just visual
  } catch {
    // AudioContext not available
  }
}

// --- Nag level calculation ---
export function getNagLevel(task: Task): number {
  if (task.done || !task.plannedTime || task.scheduledFor !== todayString()) return 0;
  const [hStr, mStr] = task.plannedTime.split(':');
  const now = new Date();
  const planned = new Date();
  planned.setHours(parseInt(hStr), parseInt(mStr), 0, 0);
  const minutesLate = (now.getTime() - planned.getTime()) / 60000;
  if (minutesLate <= 0) return 0;
  if (minutesLate < 10) return 1;
  if (minutesLate < 20) return 2;
  if (minutesLate < 40) return 3;
  if (minutesLate < 60) return 4;
  return 5;
}

// --- Messages per level ---
const nagMessages = [
  '', // 0
  "Hey, you said you'd do this by now 👀",
  "Still waiting on you... 😬",
  "YOU'RE LATE ON THIS TASK. GET ON IT. 😤",
  "THIS TASK IS NOT GOING TO DO ITSELF!! 🚨🚨",
  "⛔ DO YOUR TASK RIGHT NOW ⛔",
];

// --- Main NagSystem component ---
interface Props {
  store: AppStore;
}

export function NagSystem({ store }: Props) {
  const { state, completeTask } = store;
  const [tick, setTick] = useState(0);
  const [dismissed, setDismissed] = useState<string | null>(null); // task id of dismissed level-4+ modal
  const [dismissClicks, setDismissClicks] = useState(0);
  const soundCooldown = useRef<Record<string, number>>({});

  // Tick every 30 seconds
  useEffect(() => {
    const id = setInterval(() => setTick(t => t + 1), 30_000);
    return () => clearInterval(id);
  }, []);

  // Find worst offender
  const overdueTasks = state.tasks
    .filter(t => !t.done && t.plannedTime && t.scheduledFor === todayString())
    .map(t => ({ task: t, level: getNagLevel(t) }))
    .filter(x => x.level > 0)
    .sort((a, b) => b.level - a.level);

  const worst = overdueTasks[0];

  // Play sound when level increases (with cooldown per task)
  const playSoundIfNeeded = useCallback((taskId: string, level: number) => {
    if (level < 3) return;
    const last = soundCooldown.current[taskId] || 0;
    const cooldownMs = level >= 5 ? 60_000 : level === 4 ? 120_000 : 300_000;
    if (Date.now() - last > cooldownMs) {
      playAlarm(level);
      soundCooldown.current[taskId] = Date.now();
    }
  }, []);

  useEffect(() => {
    if (worst) playSoundIfNeeded(worst.task.id, worst.level);
  }, [tick, worst?.task.id, worst?.level, playSoundIfNeeded]);

  if (!worst || worst.level === 0) return null;

  const { task, level } = worst;
  const message = nagMessages[level];

  // Reset dismissed state if task or level changes
  const modalKey = `${task.id}-${level}`;
  const isModalDismissed = dismissed === modalKey;

  function handleDismissClick() {
    if (level >= 5) {
      // Level 5: need 5 clicks to dismiss
      const needed = 5;
      const next = dismissClicks + 1;
      if (next >= needed) {
        setDismissed(modalKey);
        setDismissClicks(0);
        // Re-show after 3 minutes
        setTimeout(() => setDismissed(null), 3 * 60_000);
      } else {
        setDismissClicks(next);
      }
    } else if (level === 4) {
      // Level 4: need 3 clicks
      const needed = 3;
      const next = dismissClicks + 1;
      if (next >= needed) {
        setDismissed(modalKey);
        setDismissClicks(0);
        setTimeout(() => setDismissed(null), 5 * 60_000);
      } else {
        setDismissClicks(next);
      }
    } else {
      setDismissed(modalKey);
      setDismissClicks(0);
      setTimeout(() => setDismissed(null), 10 * 60_000);
    }
  }

  function markDone() {
    completeTask(task.id, true);
    setDismissed(null);
    setDismissClicks(0);
  }

  // --- Level 1 & 2: Top banner only (no overlay) ---
  if (level <= 2 && !isModalDismissed) {
    return (
      <div
        className={`fixed top-0 left-0 right-0 z-40 flex items-center justify-between px-4 py-2 text-sm font-medium transition-all ${
          level === 1
            ? 'bg-orange-500/20 text-orange-300 border-b border-orange-500/30'
            : 'bg-orange-600/40 text-orange-200 border-b border-orange-400/50 animate-pulse'
        }`}
      >
        <span>⏰ <strong>{task.title}</strong> — {message}</span>
        <div className="flex gap-2">
          <button
            onClick={markDone}
            className="bg-green-600/30 hover:bg-green-600/50 text-green-300 px-3 py-1 rounded-lg text-xs transition-colors"
          >
            Done!
          </button>
          <button
            onClick={handleDismissClick}
            className="text-white/40 hover:text-white/70 px-2 py-1 rounded text-xs transition-colors"
          >
            Snooze
          </button>
        </div>
      </div>
    );
  }

  // --- Level 3: Persistent banner + can't easily snooze ---
  if (level === 3 && !isModalDismissed) {
    return (
      <div className="fixed top-0 left-0 right-0 z-40 bg-red-600/50 border-b-2 border-red-400 text-white px-4 py-3 flex items-center justify-between">
        <div>
          <div className="font-bold text-base">🚨 {message}</div>
          <div className="text-sm text-red-200">"{task.title}"</div>
        </div>
        <div className="flex gap-2">
          <button
            onClick={markDone}
            className="bg-green-500 hover:bg-green-400 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors"
          >
            Done!
          </button>
          <button
            onClick={handleDismissClick}
            className="bg-white/10 hover:bg-white/20 text-white/60 px-3 py-2 rounded-lg text-xs transition-colors"
          >
            Go away (10 min)
          </button>
        </div>
      </div>
    );
  }

  // --- Level 4+: Full-screen overlay ---
  if (level >= 4 && !isModalDismissed) {
    const isLevel5 = level >= 5;
    const clicksNeeded = isLevel5 ? 5 : 3;
    const clicksLeft = clicksNeeded - dismissClicks;

    return (
      <div
        className={`fixed inset-0 z-50 flex flex-col items-center justify-center p-8 ${
          isLevel5
            ? 'bg-red-900/95 animate-[pulse_0.5s_ease-in-out_infinite]'
            : 'bg-red-900/85'
        }`}
        style={isLevel5 ? { animation: 'nagFlash 0.6s ease-in-out infinite' } : {}}
      >
        <style>{`
          @keyframes nagFlash {
            0%, 100% { background-color: rgba(127, 29, 29, 0.95); }
            50% { background-color: rgba(220, 38, 38, 0.98); }
          }
          @keyframes nagShake {
            0%, 100% { transform: translateX(0); }
            20% { transform: translateX(-8px); }
            40% { transform: translateX(8px); }
            60% { transform: translateX(-6px); }
            80% { transform: translateX(6px); }
          }
        `}</style>

        <div
          className="text-center max-w-lg"
          style={{ animation: isLevel5 ? 'nagShake 0.4s ease-in-out infinite' : 'none' }}
        >
          <div className="text-6xl mb-4">{isLevel5 ? '⛔' : '🚨'}</div>
          <div className={`font-black mb-3 ${isLevel5 ? 'text-4xl' : 'text-3xl'} text-white`}>
            {message}
          </div>
          <div className="text-xl text-red-200 mb-2">"{task.title}"</div>
          <div className="text-red-300/70 text-sm mb-8">
            {isLevel5 ? 'Over 1 hour overdue.' : 'Almost an hour overdue.'}
          </div>

          <button
            onClick={markDone}
            className="block w-full bg-green-500 hover:bg-green-400 text-white text-xl font-bold px-8 py-4 rounded-2xl mb-4 transition-colors shadow-xl"
          >
            ✓ OK OK I DID IT
          </button>

          <button
            onClick={handleDismissClick}
            className="text-red-300/50 hover:text-red-200/70 text-sm transition-colors"
          >
            {dismissClicks === 0
              ? `Dismiss (click ${clicksLeft}x to escape)`
              : `${clicksLeft} more click${clicksLeft !== 1 ? 's' : ''} to escape...`}
          </button>
        </div>
      </div>
    );
  }

  return null;
}
