import { Feather } from '@expo/vector-icons';
import { router, Stack, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Alert, Image, KeyboardAvoidingView, Linking, Platform, Pressable, ScrollView, Share, StyleSheet, Text, TextInput, View } from 'react-native';
import { KIND_ICON } from '../../components/ClipCard';
import { detectKind, toUrl } from '../../lib/detect';
import { describe, KIND_LABEL, relativeTime } from '../../lib/format';
import { clipHash } from '../../lib/hash';
import type { Clip } from '../../lib/types';
import { useStore } from '../../state/store';
import { KIND_COLOR, useColors } from '../../theme';

export default function ClipDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const isNew = id === 'new';
  const { state, dispatch, copy, addText, notify } = useStore();
  const clip = state.clips.find((x) => x.id === id);
  const c = useColors();
  const [text, setText] = useState(clip?.text ?? '');
  const [title, setTitle] = useState(clip?.title ?? '');

  if (!isNew && !clip) {
    return <Stack.Screen options={{ title: 'Nicht gefunden' }} />;
  }

  const isText = isNew || clip?.kind !== 'image';
  const dirty =
    (isText && (isNew ? text.trim() !== '' : text !== clip?.text)) || (!isNew && title !== (clip?.title ?? ''));

  const save = () => {
    if (isNew) {
      const newId = addText(text);
      if (title.trim()) dispatch({ type: 'rename', id: newId, title });
      notify('Gespeichert');
      router.back();
      return;
    }
    if (!clip) return;
    if (isText && text !== clip.text && text.trim()) {
      dispatch({ type: 'edit', id: clip.id, text, kind: detectKind(text), hash: clipHash('text', text) });
    }
    if (title !== (clip.title ?? '')) dispatch({ type: 'rename', id: clip.id, title });
    notify('Gespeichert');
  };

  const remove = () => {
    if (!clip) return;
    const go = () => {
      dispatch({ type: 'delete', id: clip.id });
      router.back();
    };
    if (Platform.OS === 'web') return go();
    Alert.alert('Eintrag löschen?', clip.pinboardIds.length ? 'Er wird auch aus allen Pinnwänden entfernt.' : undefined, [
      { text: 'Abbrechen', style: 'cancel' },
      { text: 'Löschen', style: 'destructive', onPress: go },
    ]);
  };

  const share = (x: Clip) =>
    Share.share(x.kind === 'image' ? { url: x.imageUri ?? '' } : { message: x.text ?? '' }).catch(() => {});

  const openTarget = (x: Clip) => {
    const t = x.text?.trim() ?? '';
    const url = x.kind === 'link' ? toUrl(t) : x.kind === 'email' ? `mailto:${t}` : `tel:${t.replace(/[^\d+]/g, '')}`;
    Linking.openURL(url).catch(() => notify('Konnte nicht geöffnet werden'));
  };

  const tint = clip ? KIND_COLOR[clip.kind] : KIND_COLOR.text;

  return (
    <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <Stack.Screen
        options={{
          title: isNew ? 'Neue Notiz' : (clip?.title ?? KIND_LABEL[clip!.kind]),
          headerLeft: () => (
            <Pressable onPress={() => router.back()} hitSlop={10} accessibilityRole="button">
              <Text style={{ color: c.accent, fontSize: 17 }}>Schließen</Text>
            </Pressable>
          ),
          headerRight: () =>
            dirty ? (
              <Pressable onPress={save} hitSlop={10} accessibilityRole="button">
                <Text style={{ color: c.accent, fontSize: 17, fontWeight: '600' }}>Sichern</Text>
              </Pressable>
            ) : null,
        }}
      />
      <ScrollView contentContainerStyle={styles.wrap} keyboardShouldPersistTaps="handled">
        {clip && (
          <View style={styles.metaRow}>
            <View style={[styles.badge, { backgroundColor: tint }]}>
              <Feather name={KIND_ICON[clip.kind]} size={12} color="#fff" />
              <Text style={styles.badgeText}>{KIND_LABEL[clip.kind]}</Text>
            </View>
            <Text style={[styles.meta, { color: c.muted }]}>
              {describe(clip)} · {relativeTime(clip.createdAt)}
            </Text>
          </View>
        )}

        <TextInput
          value={title}
          onChangeText={setTitle}
          placeholder="Titel (optional)"
          placeholderTextColor={c.muted}
          style={[styles.title, { color: c.text, borderColor: c.border }]}
        />

        {clip?.kind === 'image' ? (
          <Image
            source={{ uri: clip.imageUri }}
            style={[styles.image, { aspectRatio: clip.imageWidth && clip.imageHeight ? clip.imageWidth / clip.imageHeight : 1 }]}
            resizeMode="contain"
          />
        ) : (
          <>
            {clip?.kind === 'color' && (
              <View style={[styles.swatch, { backgroundColor: clip.text, borderColor: c.border }]} />
            )}
            <TextInput
              value={text}
              onChangeText={setText}
              multiline
              autoFocus={isNew}
              placeholder="Text eingeben"
              placeholderTextColor={c.muted}
              textAlignVertical="top"
              style={[
                styles.editor,
                { color: c.text, backgroundColor: c.card },
                clip?.kind === 'code' && styles.mono,
              ]}
            />
          </>
        )}

        {clip && (
          <>
            <View style={styles.actions}>
              <Action icon="copy" label="Kopieren" onPress={() => copy(clip)} />
              <Action icon="share" label="Teilen" onPress={() => share(clip)} />
              {(clip.kind === 'link' || clip.kind === 'email' || clip.kind === 'phone') && (
                <Action
                  icon={clip.kind === 'link' ? 'external-link' : clip.kind === 'email' ? 'mail' : 'phone'}
                  label="Öffnen"
                  onPress={() => openTarget(clip)}
                />
              )}
              <Action icon="trash-2" label="Löschen" danger onPress={remove} />
            </View>

            <Text style={[styles.section, { color: c.muted }]}>PINNWÄNDE</Text>
            <View style={[styles.group, { backgroundColor: c.card }]}>
              {state.pinboards.length === 0 && (
                <Pressable style={styles.row} onPress={() => router.push('/pinboard/edit')}>
                  <Feather name="plus" size={18} color={c.accent} />
                  <Text style={[styles.rowText, { color: c.accent }]}>Erste Pinnwand anlegen</Text>
                </Pressable>
              )}
              {state.pinboards.map((p, i) => {
                const on = clip.pinboardIds.includes(p.id);
                return (
                  <Pressable
                    key={p.id}
                    onPress={() => dispatch({ type: 'togglePin', clipId: clip.id, pinboardId: p.id })}
                    accessibilityRole="checkbox"
                    accessibilityState={{ checked: on }}
                    style={[styles.row, i > 0 && { borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: c.border }]}
                  >
                    <View style={[styles.dot, { backgroundColor: p.color }]} />
                    <Text style={[styles.rowText, { color: c.text }]}>{p.name}</Text>
                    {on && <Feather name="check" size={18} color={c.accent} />}
                  </Pressable>
                );
              })}
            </View>
          </>
        )}
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

function Action({
  icon,
  label,
  onPress,
  danger,
}: {
  icon: keyof typeof Feather.glyphMap;
  label: string;
  onPress: () => void;
  danger?: boolean;
}) {
  const c = useColors();
  const color = danger ? c.danger : c.accent;
  return (
    <Pressable onPress={onPress} accessibilityRole="button" style={[styles.action, { backgroundColor: c.card }]}>
      <Feather name={icon} size={20} color={color} />
      <Text style={[styles.actionText, { color }]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  wrap: { padding: 16, paddingBottom: 48, gap: 12 },
  metaRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  badge: { flexDirection: 'row', alignItems: 'center', gap: 4, paddingHorizontal: 8, paddingVertical: 3, borderRadius: 6 },
  badgeText: { color: '#fff', fontSize: 12, fontWeight: '600' },
  meta: { fontSize: 13 },
  title: { fontSize: 20, fontWeight: '600', paddingVertical: 6, borderBottomWidth: StyleSheet.hairlineWidth },
  editor: { minHeight: 180, borderRadius: 12, padding: 12, fontSize: 16, lineHeight: 22 },
  mono: { fontFamily: 'Menlo', fontSize: 14 },
  image: { width: '100%', borderRadius: 12 },
  swatch: { height: 90, borderRadius: 12, borderWidth: StyleSheet.hairlineWidth },
  actions: { flexDirection: 'row', gap: 8 },
  action: { flex: 1, alignItems: 'center', gap: 4, paddingVertical: 12, borderRadius: 12 },
  actionText: { fontSize: 12, fontWeight: '600' },
  section: { fontSize: 12, fontWeight: '600', marginTop: 8, marginLeft: 4 },
  group: { borderRadius: 12, overflow: 'hidden' },
  row: { flexDirection: 'row', alignItems: 'center', gap: 12, paddingHorizontal: 14, paddingVertical: 13 },
  rowText: { flex: 1, fontSize: 16 },
  dot: { width: 12, height: 12, borderRadius: 6 },
});
