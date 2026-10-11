import { Feather } from '@expo/vector-icons';
import { router, useNavigation } from 'expo-router';
import { useLayoutEffect, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { KIND_ICON } from '../../components/ClipCard';
import { ClipList, EmptyState, IconButton } from '../../components/ui';
import { KIND_LABEL } from '../../lib/format';
import { filterClips } from '../../lib/history';
import type { ClipKind } from '../../lib/types';
import { useStore } from '../../state/store';
import { KIND_COLOR, useColors } from '../../theme';

const KINDS: ClipKind[] = ['text', 'link', 'image', 'color', 'code', 'email', 'phone'];

export default function HistoryScreen() {
  const { state, capture } = useStore();
  const c = useColors();
  const navigation = useNavigation();
  const [query, setQuery] = useState('');
  const [kind, setKind] = useState<ClipKind | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  useLayoutEffect(() => {
    navigation.setOptions({
      headerRight: () => (
        <View style={styles.headerBtns}>
          <IconButton name="edit-3" label="Neue Notiz" onPress={() => router.push('/clip/new')} />
          <IconButton name="clipboard" label="Aus Zwischenablage einfügen" onPress={() => capture(true)} />
        </View>
      ),
    });
  }, [navigation, capture]);

  const clips = useMemo(() => filterClips(state.clips, { query, kind }), [state.clips, query, kind]);
  const present = useMemo(() => new Set(state.clips.map((x) => x.kind)), [state.clips]);

  const refresh = async () => {
    setRefreshing(true);
    await capture(true);
    setRefreshing(false);
  };

  const header = (
    <View>
      <View style={[styles.search, { backgroundColor: c.chip }]}>
        <Feather name="search" size={16} color={c.muted} />
        <TextInput
          value={query}
          onChangeText={setQuery}
          placeholder="Verlauf durchsuchen"
          placeholderTextColor={c.muted}
          style={[styles.searchInput, { color: c.text }]}
          clearButtonMode="while-editing"
          autoCorrect={false}
          returnKeyType="search"
        />
      </View>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.chips}>
        <Chip label="Alle" active={!kind} onPress={() => setKind(null)} />
        {KINDS.filter((k) => present.has(k)).map((k) => (
          <Chip
            key={k}
            label={KIND_LABEL[k]}
            icon={KIND_ICON[k]}
            tint={KIND_COLOR[k]}
            active={kind === k}
            onPress={() => setKind(kind === k ? null : k)}
          />
        ))}
      </ScrollView>
    </View>
  );

  const filtered = query.trim() !== '' || kind !== null;
  return (
    <ClipList
      clips={clips}
      header={header}
      onRefresh={refresh}
      refreshing={refreshing}
      empty={
        filtered ? (
          <EmptyState icon="search" title="Nichts gefunden" text="Andere Suche oder anderen Filter probieren." />
        ) : (
          <EmptyState
            icon="clipboard"
            title="Noch nichts kopiert"
            text={'Kopiere irgendwo Text, einen Link oder ein Bild und öffne dann Ablage.\nOder nach unten ziehen, um die Zwischenablage einzufügen.'}
          />
        )
      }
    />
  );
}

function Chip({
  label,
  icon,
  tint,
  active,
  onPress,
}: {
  label: string;
  icon?: keyof typeof Feather.glyphMap;
  tint?: string;
  active: boolean;
  onPress: () => void;
}) {
  const c = useColors();
  const bg = active ? (tint ?? c.accent) : c.chip;
  const fg = active ? '#fff' : c.text;
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityState={{ selected: active }}
      style={[styles.chip, { backgroundColor: bg }]}
    >
      {icon && <Feather name={icon} size={13} color={active ? '#fff' : (tint ?? c.muted)} />}
      <Text style={[styles.chipText, { color: fg }]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  headerBtns: { flexDirection: 'row', gap: 10, marginRight: 10 },
  search: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginHorizontal: 16,
    paddingHorizontal: 12,
    borderRadius: 10,
    height: 38,
  },
  searchInput: { flex: 1, fontSize: 16, height: 38 },
  chips: { paddingHorizontal: 16, paddingVertical: 12, gap: 8 },
  chip: { flexDirection: 'row', alignItems: 'center', gap: 5, paddingHorizontal: 12, height: 30, borderRadius: 15 },
  chipText: { fontSize: 13, fontWeight: '600' },
});
