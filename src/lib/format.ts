import type { Clip, ClipKind } from './types';

export const KIND_LABEL: Record<ClipKind, string> = {
  text: 'Text',
  link: 'Link',
  image: 'Bild',
  color: 'Farbe',
  email: 'E-Mail',
  phone: 'Telefon',
  code: 'Code',
};

export function relativeTime(ts: number, now = Date.now()): string {
  const s = Math.max(0, Math.round((now - ts) / 1000));
  if (s < 60) return 'gerade eben';
  const m = Math.round(s / 60);
  if (m < 60) return `vor ${m} Min.`;
  const h = Math.round(m / 60);
  if (h < 24) return `vor ${h} Std.`;
  const d = Math.round(h / 24);
  if (d === 1) return 'gestern';
  if (d < 7) return `vor ${d} Tagen`;
  return new Date(ts).toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit', year: '2-digit' });
}

export function preview(text: string, max = 280): string {
  const t = text.replace(/\s+$/g, '');
  return t.length > max ? `${t.slice(0, max)}…` : t;
}

export function describe(clip: Clip): string {
  if (clip.kind === 'image') {
    return clip.imageWidth ? `${clip.imageWidth} × ${clip.imageHeight}` : 'Bild';
  }
  const len = clip.text?.length ?? 0;
  const words = clip.text?.trim().split(/\s+/).filter(Boolean).length ?? 0;
  return words > 1 ? `${words} Wörter` : `${len} Zeichen`;
}
