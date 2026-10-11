import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useCallback } from 'react';
import { FlatList, Pressable, StyleSheet, Text, View, type ListRenderItem } from 'react-native';
import type { Clip } from '../lib/types';
import { useStore } from '../state/store';
import { useColors } from '../theme';
import { ClipCard } from './ClipCard';

export function IconButton({
  name,
  label,
  onPress,
  color,
}: {
  name: keyof typeof Feather.glyphMap;
  label: string;
  onPress: () => void;
  color?: string;
}) {
  const c = useColors();
  return (
    <Pressable onPress={onPress} hitSlop={10} accessibilityRole="button" accessibilityLabel={label} style={styles.iconBtn}>
      <Feather name={name} size={22} color={color ?? c.accent} />
    </Pressable>
  );
}

export function Toast() {
  const { toast } = useStore();
  const c = useColors();
  if (!toast) return null;
  return (
    <View pointerEvents="none" style={styles.toastWrap}>
      <View style={[styles.toast, { backgroundColor: c.overlay }]}>
        <Text style={[styles.toastText, { color: c.bg }]}>{toast}</Text>
      </View>
    </View>
  );
}

export function EmptyState({ icon, title, text }: { icon: keyof typeof Feather.glyphMap; title: string; text: string }) {
  const c = useColors();
  return (
    <View style={styles.empty}>
      <Feather name={icon} size={40} color={c.muted} />
      <Text style={[styles.emptyTitle, { color: c.text }]}>{title}</Text>
      <Text style={[styles.emptyText, { color: c.muted }]}>{text}</Text>
    </View>
  );
}

/** Kartenliste, die Verlauf und Pinnwand gemeinsam nutzen. */
export function ClipList({
  clips,
  empty,
  header,
  onRefresh,
  refreshing,
}: {
  clips: Clip[];
  empty: React.ReactElement;
  header?: React.ReactElement;
  onRefresh?: () => void;
  refreshing?: boolean;
}) {
  const { state, copy } = useStore();
  const open = useCallback((clip: Clip) => router.push(`/clip/${clip.id}`), []);
  const renderItem: ListRenderItem<Clip> = useCallback(
    ({ item }) => <ClipCard clip={item} pinboards={state.pinboards} onPress={copy} onOpen={open} />,
    [state.pinboards, copy, open],
  );
  return (
    <FlatList
      data={clips}
      keyExtractor={(c) => c.id}
      renderItem={renderItem}
      ListHeaderComponent={header}
      ListEmptyComponent={empty}
      contentContainerStyle={{ paddingTop: 8, paddingBottom: 32, flexGrow: 1 }}
      keyboardDismissMode="on-drag"
      keyboardShouldPersistTaps="handled"
      onRefresh={onRefresh}
      refreshing={refreshing ?? false}
      initialNumToRender={8}
      windowSize={7}
    />
  );
}

const styles = StyleSheet.create({
  iconBtn: { paddingHorizontal: 6 },
  toastWrap: { position: 'absolute', left: 0, right: 0, bottom: 110, alignItems: 'center' },
  toast: { paddingHorizontal: 18, paddingVertical: 10, borderRadius: 20 },
  toastText: { fontWeight: '600', fontSize: 14 },
  empty: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32, gap: 10 },
  emptyTitle: { fontSize: 18, fontWeight: '600' },
  emptyText: { fontSize: 14, textAlign: 'center', lineHeight: 20 },
});
