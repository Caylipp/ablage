import { useColorScheme } from 'react-native';
import type { ClipKind } from '../lib/types';

const light = {
  bg: '#F2F2F5',
  card: '#FFFFFF',
  text: '#16171A',
  muted: '#6E7179',
  border: '#E2E3E8',
  accent: '#3D7BFD',
  danger: '#E5484D',
  chip: '#E6E7EC',
  overlay: 'rgba(22,23,26,0.92)',
};

const dark: typeof light = {
  bg: '#101114',
  card: '#1C1D22',
  text: '#F2F3F5',
  muted: '#9497A0',
  border: '#2B2D33',
  accent: '#5B8FFF',
  danger: '#FF6369',
  chip: '#26282E',
  overlay: 'rgba(242,243,245,0.94)',
};

export type Colors = typeof light;

export const KIND_COLOR: Record<ClipKind, string> = {
  text: '#3D7BFD',
  link: '#2FB36B',
  image: '#9B5CF6',
  color: '#F59E0B',
  email: '#14B8A6',
  phone: '#EC4899',
  code: '#64748B',
};

export const PINBOARD_COLORS = ['#E5484D', '#F59E0B', '#2FB36B', '#14B8A6', '#3D7BFD', '#9B5CF6', '#EC4899', '#64748B'];

export function useColors(): Colors {
  return useColorScheme() === 'dark' ? dark : light;
}
