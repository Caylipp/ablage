import { Feather } from '@expo/vector-icons';
import { router, Stack, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Alert, Platform, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { newId } from '../../lib/hash';
import { useStore } from '../../state/store';
import { PINBOARD_COLORS, useColors } from '../../theme';

export default function EditPinboard() {
  const { id } = useLocalSearchParams<{ id?: string }>();
  const { state, dispatch } = useStore();
  const board = state.pinboards.find((p) => p.id === id);
  const c = useColors();
  const [name, setName] = useState(board?.name ?? '');
  const [color, setColor] = useState(board?.color ?? PINBOARD_COLORS[state.pinboards.length % PINBOARD_COLORS.length]);

  const save = () => {
    const n = name.trim();
    if (!n) return;
    if (board) dispatch({ type: 'updatePinboard', id: board.id, name: n, color });
    else dispatch({ type: 'createPinboard', pinboard: { id: newId(), name: n, color, createdAt: Date.now() } });
    router.back();
  };

  const remove = () => {
    if (!board) return;
    const go = () => {
      dispatch({ type: 'deletePinboard', id: board.id });
      router.dismissTo('/pinboards');
    };
    if (Platform.OS === 'web') return go();
    Alert.alert(`„${board.name}“ löschen?`, 'Die Einträge bleiben im Verlauf erhalten.', [
      { text: 'Abbrechen', style: 'cancel' },
      { text: 'Löschen', style: 'destructive', onPress: go },
    ]);
  };

  return (
    <View style={styles.wrap}>
      <Stack.Screen
        options={{
          title: board ? 'Pinnwand bearbeiten' : 'Neue Pinnwand',
          headerLeft: () => (
            <Pressable onPress={() => router.back()} hitSlop={10}>
              <Text style={{ color: c.accent, fontSize: 17 }}>Abbrechen</Text>
            </Pressable>
          ),
          headerRight: () => (
            <Pressable onPress={save} hitSlop={10} disabled={!name.trim()}>
              <Text style={{ color: name.trim() ? c.accent : c.muted, fontSize: 17, fontWeight: '600' }}>Sichern</Text>
            </Pressable>
          ),
        }}
      />
      <TextInput
        value={name}
        onChangeText={setName}
        placeholder="Name, z. B. Arbeit"
        placeholderTextColor={c.muted}
        autoFocus
        returnKeyType="done"
        onSubmitEditing={save}
        style={[styles.input, { color: c.text, backgroundColor: c.card }]}
      />
      <Text style={[styles.label, { color: c.muted }]}>FARBE</Text>
      <View style={styles.colors}>
        {PINBOARD_COLORS.map((col) => (
          <Pressable
            key={col}
            onPress={() => setColor(col)}
            accessibilityRole="radio"
            accessibilityState={{ selected: col === color }}
            style={[styles.color, { backgroundColor: col }]}
          >
            {col === color && <Feather name="check" size={20} color="#fff" />}
          </Pressable>
        ))}
      </View>
      {board && (
        <Pressable onPress={remove} style={[styles.delete, { backgroundColor: c.card }]}>
          <Feather name="trash-2" size={18} color={c.danger} />
          <Text style={{ color: c.danger, fontSize: 16 }}>Pinnwand löschen</Text>
        </Pressable>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { padding: 16, gap: 12 },
  input: { fontSize: 18, padding: 14, borderRadius: 12 },
  label: { fontSize: 12, fontWeight: '600', marginTop: 8, marginLeft: 4 },
  colors: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  color: { width: 44, height: 44, borderRadius: 22, alignItems: 'center', justifyContent: 'center' },
  delete: { flexDirection: 'row', alignItems: 'center', gap: 10, padding: 14, borderRadius: 12, marginTop: 24 },
});
