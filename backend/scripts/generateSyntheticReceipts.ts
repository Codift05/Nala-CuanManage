import { mkdir, writeFile, unlink } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { join, resolve } from 'node:path';

const outputDirectory = resolve(
  process.argv[2] ?? '../docs/evaluation/synthetic_receipts',
);
const imageDirectory = join(outputDirectory, 'images');
const font = '/usr/share/fonts/adobe-source-code-pro-fonts/SourceCodePro-Medium.otf';

const merchants = [
  ['Kantin Teknik Unsrat', 'Food'],
  ['Warung Bahu', 'Food'],
  ['Toko Nala Manado', 'Shopping'],
  ['Minimarket Kampus', 'Shopping'],
  ['Ojek Sario', 'Transport'],
  ['Trans Manado', 'Transport'],
  ['PLN Manado', 'Bills'],
  ['Internet Mahasiswa', 'Bills'],
  ['Apotek Malalayang', 'Others'],
  ['Fotokopi Tikala', 'Others'],
] as const;
const conditions = ['clean', 'rotate-left', 'rotate-right', 'low-contrast', 'blur', 'noise'] as const;

const escapeXml = (value: string) => value.replace(/[&<>]/g, (character) => ({
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
})[character]!);

const main = async () => {
  await mkdir(imageDirectory, { recursive: true });
  const manifest = [];

  for (let index = 0; index < 30; index++) {
    const [merchant, categoryId] = merchants[index % merchants.length]!;
    const condition = conditions[index % conditions.length]!;
    const amount = 12000 + index * 3750;
    const id = `synthetic-${String(index + 1).padStart(3, '0')}`;
    const svgPath = join(outputDirectory, `${id}.svg`);
    const imagePath = join(imageDirectory, `${id}.jpg`);
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="1040">
<rect width="720" height="1040" fill="#fffdf7"/>
<g font-family="Source Code Pro" fill="#171717" text-anchor="middle">
<text x="360" y="95" font-size="34" font-weight="bold">${escapeXml(merchant)}</text>
<text x="360" y="140" font-size="20">MANADO, SULAWESI UTARA</text>
<text x="360" y="190" font-size="18">02/08/2026  12:${String(index).padStart(2, '0')}</text>
<text x="70" y="270" text-anchor="start" font-size="23">ITEM ${String(index + 1).padStart(2, '0')}</text>
<text x="650" y="270" text-anchor="end" font-size="23">Rp ${amount.toLocaleString('id-ID')}</text>
<line x1="65" y1="320" x2="655" y2="320" stroke="#333" stroke-dasharray="8 8"/>
<text x="70" y="395" text-anchor="start" font-size="30" font-weight="bold">TOTAL</text>
<text x="650" y="395" text-anchor="end" font-size="30" font-weight="bold">Rp ${amount.toLocaleString('id-ID')}</text>
<text x="360" y="500" font-size="19">PEMBAYARAN BERHASIL</text>
<text x="360" y="900" font-size="18">TERIMA KASIH</text>
<text x="360" y="940" font-size="15">STRUK SINTETIS NALA - BUKAN TRANSAKSI NYATA</text>
</g></svg>`;
    await writeFile(svgPath, svg);

    const effects = condition === 'rotate-left' ? ['-rotate', '-2']
      : condition === 'rotate-right' ? ['-rotate', '2']
      : condition === 'low-contrast' ? ['-contrast', '-contrast']
      : condition === 'blur' ? ['-blur', '0x0.8']
      : condition === 'noise' ? ['-attenuate', '0.15', '+noise', 'Gaussian']
      : [];
    const rendered = spawnSync('magick', [
      '-background', '#ececec',
      '-font', font,
      svgPath,
      ...effects,
      '-strip',
      '-quality', '82',
      imagePath,
    ], { encoding: 'utf8' });
    await unlink(svgPath);
    if (rendered.status !== 0) throw new Error(rendered.stderr);

    manifest.push({
      id,
      synthetic: true,
      image: `images/${id}.jpg`,
      condition,
      groundTruth: { amount, merchant, categoryId },
    });
  }

  await writeFile(
    join(outputDirectory, 'manifest.json'),
    `${JSON.stringify(manifest, null, 2)}\n`,
  );
  console.log(`Generated ${manifest.length} synthetic receipts in ${outputDirectory}`);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
