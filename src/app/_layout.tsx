import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { View } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { Toast } from '../components/ui';
import { StoreProvider } from '../state/store';
import { useColors } from '../theme';

function Root() {
  const c = useColors();
  return (
    <View style={{ flex: 1, backgroundColor: c.bg }}>
      <StatusBar style="auto" />
      <Stack
        screenOptions={{
          headerStyle: { backgroundColor: c.bg },
          headerTintColor: c.accent,
          headerTitleStyle: { color: c.text },
          headerShadowVisible: false,
          contentStyle: { backgroundColor: c.bg },
        }}
      >
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="clip/[id]" options={{ presentation: 'modal', title: 'Eintrag' }} />
        <Stack.Screen name="pinboard/[id]" options={{ title: 'Pinnwand' }} />
        <Stack.Screen name="pinboard/edit" options={{ presentation: 'modal', title: 'Pinnwand' }} />
        <Stack.Screen name="add" options={{ headerShown: false }} />
      </Stack>
      <Toast />
    </View>
  );
}

export default function Layout() {
  return (
    <SafeAreaProvider>
      <StoreProvider>
        <Root />
      </StoreProvider>
    </SafeAreaProvider>
  );
}
