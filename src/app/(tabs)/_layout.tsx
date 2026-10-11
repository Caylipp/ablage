import { Feather } from '@expo/vector-icons';
import { Tabs } from 'expo-router';
import { useColors } from '../../theme';

export default function TabLayout() {
  const c = useColors();
  return (
    <Tabs
      screenOptions={{
        headerStyle: { backgroundColor: c.bg },
        headerTitleStyle: { color: c.text },
        headerShadowVisible: false,
        tabBarActiveTintColor: c.accent,
        tabBarInactiveTintColor: c.muted,
        tabBarStyle: { backgroundColor: c.card, borderTopColor: c.border },
        sceneStyle: { backgroundColor: c.bg },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{ title: 'Verlauf', tabBarIcon: ({ color, size }) => <Feather name="clock" color={color} size={size} /> }}
      />
      <Tabs.Screen
        name="pinboards"
        options={{ title: 'Pinnwände', tabBarIcon: ({ color, size }) => <Feather name="layers" color={color} size={size} /> }}
      />
      <Tabs.Screen
        name="settings"
        options={{ title: 'Einstellungen', tabBarIcon: ({ color, size }) => <Feather name="settings" color={color} size={size} /> }}
      />
    </Tabs>
  );
}
