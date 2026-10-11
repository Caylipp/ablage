import { router, Stack, useLocalSearchParams } from 'expo-router';
import { useMemo } from 'react';
import { View } from 'react-native';
import { ClipList, EmptyState, IconButton } from '../../components/ui';
import { filterClips } from '../../lib/history';
import { useStore } from '../../state/store';

export default function PinboardScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { state } = useStore();
  const board = state.pinboards.find((p) => p.id === id);
  const clips = useMemo(() => filterClips(state.clips, { pinboardId: id }), [state.clips, id]);

  return (
    <View style={{ flex: 1 }}>
      <Stack.Screen
        options={{
          title: board?.name ?? 'Pinnwand',
          headerRight: () =>
            board ? (
              <IconButton name="edit-2" label="Pinnwand bearbeiten" onPress={() => router.push(`/pinboard/edit?id=${board.id}`)} />
            ) : null,
        }}
      />
      <ClipList
        clips={clips}
        empty={
          <EmptyState
            icon="bookmark"
            title="Noch leer"
            text="Im Verlauf eine Karte lange drücken und unter „Pinnwände“ diese Pinnwand anhaken."
          />
        }
      />
    </View>
  );
}
