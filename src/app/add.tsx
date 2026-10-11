import { Redirect, useLocalSearchParams } from 'expo-router';
import { useEffect, useRef } from 'react';
import { useStore } from '../state/store';

/** Ziel des URL-Schemas ablage://add?text=… (z. B. aus einem Kurzbefehl). */
export default function AddFromUrl() {
  const { text } = useLocalSearchParams<{ text?: string }>();
  const { loaded, addText, notify } = useStore();
  const done = useRef(false);

  useEffect(() => {
    if (!loaded || done.current) return;
    done.current = true;
    if (text?.trim()) {
      addText(text);
      notify('Aus Kurzbefehl gesichert');
    }
  }, [loaded, text, addText, notify]);

  return loaded ? <Redirect href="/" /> : null;
}
