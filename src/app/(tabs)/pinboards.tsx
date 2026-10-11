import { Feather } from '@expo/vector-icons';
import { router, useNavigation } from 'expo-router';
import { useLayoutEffect } from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { EmptyState, IconButton } from '../../components/ui';
import { useStore } from '../../state/store';
import { useColors } from '../../theme';

export default function PinboardsScreen() {
  const { state } = useStore();
  const c = useColors();
  const navigation = useNavigation();

  useLayoutEffect(() => {
    navigation.setOptions({
      headerRight: () => (
        <View style={{ marginRight: 10 }}>
          <IconButton name="plus" label="Neue Pinnwand" onPress={() => router.push('/pinboard/edit')} />
        </View>
      ),
    });
  }, [navigation]);

  const count = (id: string) => state.clips.filter((x) => x.pinboardIds.includes(id)).length;

  return (
    <FlatList
      data={state.pinboards}
      keyExtractor={(p) => p.id}
      contentContainerStyle={{ padding: 16, gap: 12, flexGrow: 1 }}
      ListEmptyComponent={
        <EmptyState
          icon="layers"
          title="Keine Pinnwände"
          text={'Pinnwände sammeln Einträge dauerhaft – sie bleiben, auch wenn der Verlauf geleert wird.\nOben rechts mit Plus anlegen.'}
        />
      }
      renderItem={({ item }) => {
        const n = count(item.id);
        return (
          <Pressable
            onPress={() => router.push(`/pinboard/${item.id}`)}
            accessibilityRole="button"
            style={({ pressed }) => [styles.card, { backgroundColor: c.card, opacity: pressed ? 0.75 : 1 }]}
          >
            <View style={[styles.icon, { backgroundColor: item.color }]}>
              <Feather name="layers" size={20} color="#fff" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={[styles.name, { color: c.text }]}>{item.name}</Text>
              <Text style={[styles.count, { color: c.muted }]}>
                {n} {n === 1 ? 'Eintrag' : 'Einträge'}
              </Text>
            </View>
            <Feather name="chevron-right" size={20} color={c.muted} />
          </Pressable>
        );
      }}
    />
  );
}

const styles = StyleSheet.create({
  card: { flexDirection: 'row', alignItems: 'center', gap: 14, padding: 14, borderRadius: 14 },
  icon: { width: 42, height: 42, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
  name: { fontSize: 17, fontWeight: '600' },
  count: { fontSize: 13, marginTop: 2 },
});
