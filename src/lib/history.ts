import type { Clip, ClipKind, Pinboard, Settings, State } from './types';

export type NewClip = Pick<Clip, 'kind' | 'hash' | 'text' | 'imageUri' | 'imageWidth' | 'imageHeight'>;

export type Action =
  | { type: 'load'; state: State }
  | { type: 'add'; clip: NewClip; id: string; now: number }
  | { type: 'touch'; id: string; now: number }
  | { type: 'edit'; id: string; text: string; kind: ClipKind; hash: string }
  | { type: 'rename'; id: string; title: string }
  | { type: 'delete'; id: string }
  | { type: 'clearHistory' }
  | { type: 'togglePin'; clipId: string; pinboardId: string }
  | { type: 'createPinboard'; pinboard: Pinboard }
  | { type: 'updatePinboard'; id: string; name: string; color: string }
  | { type: 'deletePinboard'; id: string }
  | { type: 'settings'; patch: Partial<Settings> };

const isPinned = (c: Clip) => c.pinboardIds.length > 0;

/** Kürzt nur ungepinnte Einträge auf das Limit; die Liste ist nach usedAt absteigend sortiert. */
export function applyLimit(clips: Clip[], limit: number): Clip[] {
  let loose = 0;
  return clips.filter((c) => isPinned(c) || ++loose <= limit);
}

function moveToFront(clips: Clip[], id: string, patch: Partial<Clip>): Clip[] {
  const found = clips.find((c) => c.id === id);
  if (!found) return clips;
  return [{ ...found, ...patch }, ...clips.filter((c) => c.id !== id)];
}

const mapClip = (s: State, id: string, f: (c: Clip) => Clip): State => ({
  ...s,
  clips: s.clips.map((c) => (c.id === id ? f(c) : c)),
});

export function reducer(s: State, a: Action): State {
  switch (a.type) {
    case 'load':
      return a.state;
    case 'add': {
      const dup = s.clips.find((c) => c.hash === a.clip.hash);
      if (dup) return { ...s, clips: moveToFront(s.clips, dup.id, { usedAt: a.now }) };
      const clip: Clip = { ...a.clip, id: a.id, createdAt: a.now, usedAt: a.now, pinboardIds: [] };
      return { ...s, clips: applyLimit([clip, ...s.clips], s.settings.historyLimit) };
    }
    case 'touch':
      return { ...s, clips: moveToFront(s.clips, a.id, { usedAt: a.now }) };
    case 'edit':
      return mapClip(s, a.id, (c) => ({ ...c, text: a.text, kind: a.kind, hash: a.hash }));
    case 'rename':
      return mapClip(s, a.id, (c) => ({ ...c, title: a.title.trim() || undefined }));
    case 'delete':
      return { ...s, clips: s.clips.filter((c) => c.id !== a.id) };
    case 'clearHistory':
      return { ...s, clips: s.clips.filter(isPinned) };
    case 'togglePin':
      return mapClip(s, a.clipId, (c) => ({
        ...c,
        pinboardIds: c.pinboardIds.includes(a.pinboardId)
          ? c.pinboardIds.filter((p) => p !== a.pinboardId)
          : [...c.pinboardIds, a.pinboardId],
      }));
    case 'createPinboard':
      return { ...s, pinboards: [...s.pinboards, a.pinboard] };
    case 'updatePinboard':
      return {
        ...s,
        pinboards: s.pinboards.map((p) => (p.id === a.id ? { ...p, name: a.name, color: a.color } : p)),
      };
    case 'deletePinboard': {
      const clips = s.clips.map((c) =>
        c.pinboardIds.includes(a.id) ? { ...c, pinboardIds: c.pinboardIds.filter((p) => p !== a.id) } : c,
      );
      return {
        ...s,
        pinboards: s.pinboards.filter((p) => p.id !== a.id),
        clips: applyLimit(clips, s.settings.historyLimit),
      };
    }
    case 'settings': {
      const settings = { ...s.settings, ...a.patch };
      return { ...s, settings, clips: applyLimit(s.clips, settings.historyLimit) };
    }
  }
}

export interface ClipFilter {
  query?: string;
  kind?: ClipKind | null;
  pinboardId?: string | null;
}

export function filterClips(clips: Clip[], f: ClipFilter): Clip[] {
  const q = f.query?.trim().toLowerCase();
  return clips.filter(
    (c) =>
      (!f.kind || c.kind === f.kind) &&
      (!f.pinboardId || c.pinboardIds.includes(f.pinboardId)) &&
      (!q || (c.text ?? '').toLowerCase().includes(q) || (c.title ?? '').toLowerCase().includes(q)),
  );
}

/** Bilddateien, die nach einer Änderung von keinem Eintrag mehr referenziert werden. */
export function orphanedImages(prev: Clip[], next: Clip[]): string[] {
  const keep = new Set(next.map((c) => c.imageUri).filter(Boolean));
  return prev.map((c) => c.imageUri).filter((u): u is string => !!u && !keep.has(u));
}
