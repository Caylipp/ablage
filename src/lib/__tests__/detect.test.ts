import { detectKind, domainOf, toUrl } from '../detect';

describe('detectKind', () => {
  it.each([
    ['#ff8800', 'color'],
    ['#FFF', 'color'],
    ['rgb(10, 20, 30)', 'color'],
    ['hsl(200, 50%, 40%)', 'color'],
    ['max@beispiel.de', 'email'],
    ['https://example.com/a?b=1', 'link'],
    ['www.spiegel.de', 'link'],
    ['github.com/expo/expo', 'link'],
    ['+49 170 1234567', 'phone'],
    ['0170/1234567', 'phone'],
    ['const a = 1;\nreturn a;', 'code'],
    ['function f() { return 1; }', 'code'],
    ['Hallo Welt, wie geht es?', 'text'],
    ['12', 'text'],
    ['Einkaufen: Milch; Brot', 'text'],
    ['', 'text'],
  ])('%s → %s', (input, kind) => {
    expect(detectKind(input)).toBe(kind);
  });

  it('erkennt mehrzeiligen Text mit Link nicht als Link', () => {
    expect(detectKind('schau mal\nhttps://x.de')).toBe('text');
  });
});

describe('url helpers', () => {
  it('ergänzt https', () => expect(toUrl('www.x.de')).toBe('https://www.x.de'));
  it('liefert Domain', () => expect(domainOf('https://www.spiegel.de/a/b')).toBe('spiegel.de'));
});
