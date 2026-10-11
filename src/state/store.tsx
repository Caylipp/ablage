import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Haptics from 'expo-haptics';
import { createContext, useCallback, useContext, useEffect, useMemo, useReducer, useRef, useState, type ReactNode } from 'react';
import { AppState, Platform } from 'react-native';
import { newId } from '../lib/hash';
import { orphanedImages, reducer, type Action } from '../lib/history';
import { DEFAULT_SETTINGS, EMPTY_STATE, type Clip, type State } from '../lib/types';
import { deleteImage, readClipboard, saveImage, textClip, writeClipboard } from './capture';

const KEY = 'ablage.v1';

interface Store {
  state: State;
  loaded: boolean;
  dispatch: (a: Action) => void;
  /** Liest die Zwischenablage; liefert true, wenn etwas Neues dazukam */
  capture: (manual?: boolean) => Promise<boolean>;
  copy: (clip: Clip) => Promise<void>;
  addText: (text: string) => string;
  toast: string | null;
  notify: (msg: string) => void;
}

const Ctx = createContext<Store | null>(null);

const haptic = () => {
  if (Platform.OS !== 'web') Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success).catch(() => {});
};

export function StoreProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, EMPTY_STATE);
  const [loaded, setLoaded] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const stateRef = useRef(state);
  const prevClips = useRef(state.clips);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  useEffect(() => {
    stateRef.current = state;
  }, [state]);

  useEffect(() => {
    AsyncStorage.getItem(KEY)
      .then((raw) => {
        if (!raw) return;
        const saved = JSON.parse(raw) as State;
        const next = { ...EMPTY_STATE, ...saved, settings: { ...DEFAULT_SETTINGS, ...saved.settings } };
        prevClips.current = next.clips;
        dispatch({ type: 'load', state: next });
      })
      .catch(() => {})
      .finally(() => setLoaded(true));
  }, []);

  // Speichern (entprellt) und verwaiste Bilddateien löschen
  useEffect(() => {
    if (!loaded) return;
    orphanedImages(prevClips.current, state.clips).forEach(deleteImage);
    prevClips.current = state.clips;
    const t = setTimeout(() => AsyncStorage.setItem(KEY, JSON.stringify(state)).catch(() => {}), 300);
    return () => clearTimeout(t);
  }, [state, loaded]);

  const notify = useCallback((msg: string) => {
    setToast(msg);
    clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(null), 1800);
  }, []);

  const capture = useCallback(
    async (manual = false) => {
      try {
        const got = await readClipboard();
        if (!got) {
          if (manual) notify('Zwischenablage ist leer');
          return false;
        }
        const isNew = !stateRef.current.clips.some((c) => c.hash === got.clip.hash);
        const now = Date.now();
        const id = newId(now);
        const clip = got.imageBase64 && isNew ? { ...got.clip, imageUri: saveImage(id, got.imageBase64) } : got.clip;
        dispatch({ type: 'add', clip, id, now });
        if (manual) notify(isNew ? 'Eingefügt' : 'Schon vorhanden – nach oben geholt');
        return isNew;
      } catch {
        if (manual) notify('Zwischenablage konnte nicht gelesen werden');
        return false;
      }
    },
    [notify],
  );

  const copy = useCallback(
    async (clip: Clip) => {
      await writeClipboard(clip);
      dispatch({ type: 'touch', id: clip.id, now: Date.now() });
      haptic();
      notify('Kopiert');
    },
    [notify],
  );

  const addText = useCallback((text: string) => {
    const id = newId();
    dispatch({ type: 'add', clip: textClip(text), id, now: Date.now() });
    return id;
  }, []);

  // Auto-Erfassen beim Start und jedes Mal, wenn die App wieder in den Vordergrund kommt
  useEffect(() => {
    if (!loaded) return;
    const run = () => {
      if (stateRef.current.settings.autoCapture) capture();
    };
    run();
    const sub = AppState.addEventListener('change', (s) => s === 'active' && run());
    return () => sub.remove();
  }, [loaded, capture]);

  const value = useMemo(
    () => ({ state, loaded, dispatch, capture, copy, addText, toast, notify }),
    [state, loaded, capture, copy, addText, toast, notify],
  );
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useStore(): Store {
  const s = useContext(Ctx);
  if (!s) throw new Error('StoreProvider fehlt');
  return s;
}
