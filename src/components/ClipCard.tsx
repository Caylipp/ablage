import { Feather } from '@expo/vector-icons';
import { memo } from 'react';
import { Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { domainOf } from '../lib/detect';
import { describe, KIND_LABEL, preview, relativeTime } from '../lib/format';
import type { Clip, ClipKind, Pinboard } from '../lib/types';
import { KIND_COLOR, useColors } from '../theme';

export const KIND_ICON: Record<ClipKind, keyof typeof Feather.glyphMap> = {
  text: 'type',
  link: 'link',
  image: 'image',
  color: 'droplet',
  email: 'mail',
  phone: 'phone',
  code: 'code',
};

interface Props {
  clip: Clip;
  pinboards: Pinboard[];
  onPress: (c: Clip) => void;
  onOpen: (c: Clip) => void;
}

function ClipCardBase({ clip, pinboards, onPress, onOpen }: Props) {
  const c = useColors();
  const tint = KIND_COLOR[clip.kind];
  const boards = pinboards.filter((p) => clip.pinboardIds.includes(p.id));

  return (
    <Pressable
      onPress={() => onPress(clip)}
      onLongPress={() => onOpen(clip)}
      accessibilityRole="button"
      accessibilityLabel={`${KIND_LABEL[clip.kind]} kopieren`}
      accessibilityHint="Lange drücken für Details"
      style={({ pressed }) => [styles.card, { backgroundColor: c.card, opacity: pressed ? 0.75 : 1, transform: [{ scale: pressed ? 0.985 : 1 }] }]}
    >
      <View style={[styles.head, { backgroundColor: tint }]}>
        <Feather name={KIND_ICON[clip.kind]} size={14} color="#fff" />
        <Text style={styles.headTitle} numberOfLines={1}>
          {clip.title ?? KIND_LABEL[clip.kind]}
        </Text>
        <Text style={styles.headTime}>{relativeTime(clip.usedAt)}</Text>
        <Pressable hitSlop={12} onPress={() => onOpen(clip)} accessibilityLabel="Details">
          <Feather name="more-horizontal" size={18} color="#fff" />
        </Pressable>
      </View>

      <View style={styles.body}>
        <Body clip={clip} />
      </View>

      <View style={[styles.foot, { borderTopColor: c.border }]}>
        <Text style={[styles.meta, { color: c.muted }]}>{describe(clip)}</Text>
        <View style={styles.boards}>
          {boards.map((b) => (
            <View key={b.id} style={[styles.dot, { backgroundColor: b.color }]} />
          ))}
        </View>
      </View>
    </Pressable>
  );
}

function Body({ clip }: { clip: Clip }) {
  const c = useColors();
  switch (clip.kind) {
    case 'image':
      return clip.imageUri ? (
        <Image source={{ uri: clip.imageUri }} style={styles.image} resizeMode="cover" accessibilityIgnoresInvertColors />
      ) : null;
    case 'color':
      return (
        <View style={styles.colorRow}>
          <View style={[styles.swatch, { backgroundColor: clip.text, borderColor: c.border }]} />
          <Text style={[styles.mono, { color: c.text }]}>{clip.text?.trim()}</Text>
        </View>
      );
    case 'link':
      return (
        <View>
          <Text style={[styles.domain, { color: c.text }]} numberOfLines={1}>
            {domainOf(clip.text ?? '')}
          </Text>
          <Text style={[styles.small, { color: KIND_COLOR.link }]} numberOfLines={2}>
            {clip.text}
          </Text>
        </View>
      );
    case 'code':
      return (
        <Text style={[styles.mono, { color: c.text }]} numberOfLines={8}>
          {preview(clip.text ?? '', 600)}
        </Text>
      );
    default:
      return (
        <Text style={[styles.text, { color: c.text }]} numberOfLines={6}>
          {preview(clip.text ?? '')}
        </Text>
      );
  }
}

export const ClipCard = memo(ClipCardBase);

const styles = StyleSheet.create({
  card: {
    borderRadius: 14,
    overflow: 'hidden',
    marginHorizontal: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
    elevation: 1,
  },
  head: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingHorizontal: 12, paddingVertical: 8 },
  headTitle: { color: '#fff', fontWeight: '600', fontSize: 14, flex: 1 },
  headTime: { color: 'rgba(255,255,255,0.85)', fontSize: 12 },
  body: { padding: 12, minHeight: 56 },
  text: { fontSize: 15, lineHeight: 21 },
  small: { fontSize: 13, marginTop: 2 },
  domain: { fontSize: 16, fontWeight: '600' },
  mono: { fontFamily: 'Menlo', fontSize: 13, lineHeight: 18 },
  image: { width: '100%', height: 180, borderRadius: 8 },
  colorRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  swatch: { width: 48, height: 48, borderRadius: 10, borderWidth: StyleSheet.hairlineWidth },
  foot: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  meta: { fontSize: 12 },
  boards: { flexDirection: 'row', gap: 4 },
  dot: { width: 8, height: 8, borderRadius: 4 },
});
