import * as Clipboard from 'expo-clipboard';
import { Directory, File, Paths } from 'expo-file-system';
import { Platform } from 'react-native';
import { detectKind } from '../lib/detect';
import { clipHash } from '../lib/hash';
import type { NewClip } from '../lib/history';
import type { Clip } from '../lib/types';

export interface Captured {
  clip: NewClip;
  /** Base64-Bild, wird erst gespeichert, wenn es keine Dublette ist */
  imageBase64?: string;
}

export function textClip(text: string): NewClip {
  return { kind: detectKind(text), text, hash: clipHash('text', text) };
}

/**
 * Liest die Zwischenablage. has*Async lösen auf iOS keinen „Einfügen erlauben?“-Dialog aus,
 * erst das eigentliche Lesen – darum vorher prüfen.
 */
export async function readClipboard(): Promise<Captured | null> {
  if (await Clipboard.hasImageAsync()) {
    const img = await Clipboard.getImageAsync({ format: 'png' });
    if (img?.data) {
      const b64 = img.data.slice(img.data.indexOf(',') + 1);
      return {
        clip: { kind: 'image', hash: clipHash('image', b64), imageWidth: img.size.width, imageHeight: img.size.height },
        imageBase64: b64,
      };
    }
  }
  if (await Clipboard.hasStringAsync()) {
    const text = await Clipboard.getStringAsync();
    if (text.trim()) return { clip: textClip(text) };
  }
  return null;
}

export function saveImage(id: string, b64: string): string {
  if (Platform.OS === 'web') return `data:image/png;base64,${b64}`;
  const dir = new Directory(Paths.document, 'clips');
  if (!dir.exists) dir.create({ intermediates: true });
  const file = new File(dir, `${id}.png`);
  file.write(b64, { encoding: 'base64' });
  return file.uri;
}

export function deleteImage(uri: string) {
  if (Platform.OS === 'web') return;
  try {
    const f = new File(uri);
    if (f.exists) f.delete();
  } catch {
    // Datei schon weg – egal
  }
}

export async function writeClipboard(clip: Clip): Promise<void> {
  if (clip.kind === 'image' && clip.imageUri) {
    const b64 = Platform.OS === 'web' ? clip.imageUri.split(',')[1] : await new File(clip.imageUri).base64();
    await Clipboard.setImageAsync(b64);
  } else {
    await Clipboard.setStringAsync(clip.text ?? '');
  }
}
