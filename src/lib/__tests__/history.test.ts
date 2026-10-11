import { clipHash, fnv1a } from '../hash';
import { filterClips, orphanedImages, reducer, type NewClip } from '../history';
import { relativeTime } from '../format';
import { EMPTY_STATE, type State } from '../types';

const text = (t: string): NewClip => ({ kind: 'text', text: t, hash: clipHash('text', t) });
let n = 0;
const add = (s: State, c: NewClip, now = ++n) => reducer(s, { type: 'add', clip: c, id: `id${now}`, now });

describe('history reducer', () => {
  it('fügt neueste oben ein', () => {
    const s = add(add(EMPTY_STATE, text('a')), text('b'));
    expect(s.clips.map((c) => c.text)).toEqual(['b', 'a']);
  });

  it('legt keine Dublette an, sondern holt nach oben', () => {
    let s = add(add(EMPTY_STATE, text('a')), text('b'));
    s = add(s, text('a'), 999);
    expect(s.clips.map((c) => c.text)).toEqual(['a', 'b']);
    expect(s.clips[0].usedAt).toBe(999);
  });

  it('hält Limit ein, verschont gepinnte Einträge', () => {
    let s: State = { ...EMPTY_STATE, settings: { ...EMPTY_STATE.settings, historyLimit: 2 } };
    s = add(s, text('alt'));
    s = reducer(s, { type: 'createPinboard', pinboard: { id: 'p', name: 'P', color: '#f00', createdAt: 0 } });
    s = reducer(s, { type: 'togglePin', clipId: s.clips[0].id, pinboardId: 'p' });
    s = add(add(add(s, text('1')), text('2')), text('3'));
    expect(s.clips.map((c) => c.text)).toEqual(['3', '2', 'alt']);
  });

  it('Verlauf leeren lässt Pinnwand-Einträge stehen', () => {
    let s = add(add(EMPTY_STATE, text('a')), text('b'));
    s = reducer(s, { type: 'togglePin', clipId: s.clips[1].id, pinboardId: 'p' });
    s = reducer(s, { type: 'clearHistory' });
    expect(s.clips.map((c) => c.text)).toEqual(['a']);
  });

  it('Pinnwand löschen entfernt Zuordnung', () => {
    let s = add(EMPTY_STATE, text('a'));
    s = reducer(s, { type: 'createPinboard', pinboard: { id: 'p', name: 'P', color: '#f00', createdAt: 0 } });
    s = reducer(s, { type: 'togglePin', clipId: s.clips[0].id, pinboardId: 'p' });
    s = reducer(s, { type: 'deletePinboard', id: 'p' });
    expect(s.pinboards).toHaveLength(0);
    expect(s.clips[0].pinboardIds).toEqual([]);
  });

  it('togglePin schaltet hin und zurück', () => {
    let s = add(EMPTY_STATE, text('a'));
    const id = s.clips[0].id;
    s = reducer(s, { type: 'togglePin', clipId: id, pinboardId: 'p' });
    s = reducer(s, { type: 'togglePin', clipId: id, pinboardId: 'p' });
    expect(s.clips[0].pinboardIds).toEqual([]);
  });

  it('edit, rename, touch, delete', () => {
    let s = add(add(EMPTY_STATE, text('a')), text('b'));
    const idA = s.clips[1].id;
    s = reducer(s, { type: 'edit', id: idA, text: '#fff', kind: 'color', hash: clipHash('text', '#fff') });
    s = reducer(s, { type: 'rename', id: idA, title: '  Weiß ' });
    s = reducer(s, { type: 'touch', id: idA, now: 5000 });
    expect(s.clips[0]).toMatchObject({ id: idA, kind: 'color', title: 'Weiß', usedAt: 5000 });
    s = reducer(s, { type: 'rename', id: idA, title: '' });
    expect(s.clips[0].title).toBeUndefined();
    s = reducer(s, { type: 'delete', id: idA });
    expect(s.clips.map((c) => c.text)).toEqual(['b']);
  });

  it('Limit verkleinern kürzt sofort', () => {
    let s = add(add(add(EMPTY_STATE, text('1')), text('2')), text('3'));
    s = reducer(s, { type: 'settings', patch: { historyLimit: 1 } });
    expect(s.clips.map((c) => c.text)).toEqual(['3']);
  });
});

describe('filterClips', () => {
  let s = add(EMPTY_STATE, text('Hallo Welt'));
  s = add(s, { kind: 'link', text: 'https://x.de', hash: clipHash('text', 'https://x.de') });
  s = reducer(s, { type: 'togglePin', clipId: s.clips[1].id, pinboardId: 'p' });

  it('sucht unabhängig von Groß/Klein', () => expect(filterClips(s.clips, { query: 'WELT' })).toHaveLength(1));
  it('filtert nach Typ', () => expect(filterClips(s.clips, { kind: 'link' })[0].text).toBe('https://x.de'));
  it('filtert nach Pinnwand', () => expect(filterClips(s.clips, { pinboardId: 'p' })[0].text).toBe('Hallo Welt'));
});

describe('helpers', () => {
  it('orphanedImages findet verwaiste Dateien', () => {
    const prev = [{ imageUri: 'a' }, { imageUri: 'b' }, {}] as never;
    expect(orphanedImages(prev, [{ imageUri: 'b' }] as never)).toEqual(['a']);
  });
  it('fnv1a ist stabil', () => {
    expect(fnv1a('abc')).toBe('1a47e90b');
    expect(clipHash('text', 'abc')).not.toBe(clipHash('image', 'abc'));
  });
  it('relativeTime', () => {
    expect(relativeTime(0, 10_000)).toBe('gerade eben');
    expect(relativeTime(0, 5 * 60_000)).toBe('vor 5 Min.');
    expect(relativeTime(0, 3 * 3_600_000)).toBe('vor 3 Std.');
    expect(relativeTime(0, 26 * 3_600_000)).toBe('gestern');
  });
});
