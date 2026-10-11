import { Alert, Platform, Pressable, ScrollView, StyleSheet, Switch, Text, View } from 'react-native';
import { useStore } from '../../state/store';
import { useColors } from '../../theme';

const LIMITS = [100, 500, 1000];

export default function SettingsScreen() {
  const { state, dispatch, notify } = useStore();
  const c = useColors();
  const { autoCapture, historyLimit } = state.settings;
  const pinned = state.clips.filter((x) => x.pinboardIds.length > 0).length;

  const clear = () => {
    const go = () => {
      dispatch({ type: 'clearHistory' });
      notify('Verlauf geleert');
    };
    if (Platform.OS === 'web') return go();
    Alert.alert('Verlauf leeren?', 'Einträge in Pinnwänden bleiben erhalten.', [
      { text: 'Abbrechen', style: 'cancel' },
      { text: 'Leeren', style: 'destructive', onPress: go },
    ]);
  };

  return (
    <ScrollView contentContainerStyle={styles.wrap}>
      <Section title="ERFASSEN">
        <Row>
          <Text style={[styles.rowText, { color: c.text }]}>Beim Öffnen automatisch einfügen</Text>
          <Switch value={autoCapture} onValueChange={(v) => dispatch({ type: 'settings', patch: { autoCapture: v } })} />
        </Row>
      </Section>
      <Text style={[styles.hint, { color: c.muted }]}>
        Damit iOS nicht jedes Mal „Einfügen erlauben?“ fragt: iPhone-Einstellungen → Apps → Ablage → Aus anderen Apps
        einsetzen → Erlauben.
      </Text>

      <Section title="VERLAUF BEHALTEN">
        <Row>
          {LIMITS.map((l) => (
            <Pressable
              key={l}
              onPress={() => dispatch({ type: 'settings', patch: { historyLimit: l } })}
              accessibilityRole="radio"
              accessibilityState={{ selected: l === historyLimit }}
              style={[styles.seg, { backgroundColor: l === historyLimit ? c.accent : c.chip }]}
            >
              <Text style={{ color: l === historyLimit ? '#fff' : c.text, fontWeight: '600' }}>{l}</Text>
            </Pressable>
          ))}
        </Row>
      </Section>
      <Text style={[styles.hint, { color: c.muted }]}>
        {state.clips.length} Einträge gespeichert, davon {pinned} in Pinnwänden. Pinnwand-Einträge zählen nicht zum Limit.
      </Text>

      <Section title="">
        <Pressable onPress={clear} style={styles.row}>
          <Text style={[styles.rowText, { color: c.danger }]}>Verlauf leeren</Text>
        </Pressable>
      </Section>

      <Section title="KURZBEFEHL (OHNE APP ÖFFNEN)">
        <View style={styles.guide}>
          <Text style={[styles.guideText, { color: c.text }]}>
            {'1. App „Kurzbefehle“ → neuer Kurzbefehl.\n' +
              '2. Aktion „Zwischenablage abrufen“.\n' +
              '3. Aktion „URL-Codierung“ (Codieren).\n' +
              '4. Aktion „Text“: ablage://add?text=  und dahinter die Variable „URL-codierter Text“.\n' +
              '5. Aktion „URLs öffnen“.\n\n' +
              'Tipp: Einstellungen → Bedienungshilfen → Tippen → Auf Rückseite tippen → Doppeltippen → diesen Kurzbefehl wählen. ' +
              'Dann reicht zweimal auf die iPhone-Rückseite tippen.'}
          </Text>
        </View>
      </Section>

      <Text style={[styles.hint, { color: c.muted, textAlign: 'center' }]}>
        Alle Daten bleiben nur auf diesem Gerät. Ablage 1.0
      </Text>
    </ScrollView>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  const c = useColors();
  return (
    <View>
      {!!title && <Text style={[styles.section, { color: c.muted }]}>{title}</Text>}
      <View style={[styles.group, { backgroundColor: c.card }]}>{children}</View>
    </View>
  );
}

function Row({ children }: { children: React.ReactNode }) {
  return <View style={styles.row}>{children}</View>;
}

const styles = StyleSheet.create({
  wrap: { padding: 16, gap: 8, paddingBottom: 48 },
  section: { fontSize: 12, fontWeight: '600', marginTop: 16, marginBottom: 6, marginLeft: 4 },
  group: { borderRadius: 12, overflow: 'hidden' },
  row: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingHorizontal: 14, paddingVertical: 12, minHeight: 48 },
  rowText: { flex: 1, fontSize: 16 },
  seg: { flex: 1, alignItems: 'center', paddingVertical: 8, borderRadius: 8 },
  hint: { fontSize: 13, lineHeight: 18, marginHorizontal: 4 },
  guide: { padding: 14 },
  guideText: { fontSize: 14, lineHeight: 21 },
});
