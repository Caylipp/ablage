export type ClipKind = 'text' | 'link' | 'image' | 'color' | 'email' | 'phone' | 'code';

export interface Clip {
  id: string;
  kind: ClipKind;
  /** Inhalt bei allen Text-Typen */
  text?: string;
  /** Datei-URI bei Bildern */
  imageUri?: string;
  imageWidth?: number;
  imageHeight?: number;
  /** Fingerabdruck für Dubletten */
  hash: string;
  createdAt: number;
  usedAt: number;
  title?: string;
  pinboardIds: string[];
}

export interface Pinboard {
  id: string;
  name: string;
  color: string;
  createdAt: number;
}

export interface Settings {
  autoCapture: boolean;
  historyLimit: number;
}

export interface State {
  clips: Clip[];
  pinboards: Pinboard[];
  settings: Settings;
}

export const DEFAULT_SETTINGS: Settings = { autoCapture: true, historyLimit: 500 };

export const EMPTY_STATE: State = { clips: [], pinboards: [], settings: DEFAULT_SETTINGS };
