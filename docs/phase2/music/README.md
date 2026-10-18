# A Coroa em Chamas

Composição instrumental original para a segunda fase, criada após o usuário esclarecer que queria **uma música distinta**, não a faixa inicial com ruídos/percussão sobrepostos.

32 compassos, 4/4, 150 BPM, Ré menor, 51,2 segundos. Tema de metais, ostinato de cordas, ponte de oboé e reprise com trompete. Baixo articulado e percussão acústica por notas MIDI; nenhuma gravação aprovada foi recortada, misturada ou usada como sample. Sem vozes. O tema inicial continua inalterado.

A fonte antiga `assets/audio/music/phase_two.ogg` é preservada como histórico; o catálogo agora seleciona `phase_two_distinct.ogg`. A nova composição começa no início da frase e substitui integralmente a primeira faixa após o crossfade nativo. Ela não precisa ter a mesma duração do tema anterior.

A partitura MIDI está nesta pasta. O script `tools/audio/compose_phase_two.py` contém todas as notas, instrumentos e a renderização reproduzível com FluidSynth e SoundFont **FluidR3 GM**, licença MIT (texto completo ao lado e nos créditos de jogadores). Os jogadores não precisam dessas ferramentas. Renderização local, sem serviço externo, autenticação ou créditos de geração.

O render usa uma repetição de preparação para manter a cauda da reverberação na emenda, sem chorus, sem segmentação de gravações e sem pausa no loop. Aplica apenas remoção de DC/graves subaudíveis, correção curta da fronteira e ganho de pico de aproximadamente −5 dBFS. Métricas do OGG decodificado em `metrics.json`; zero samples saturadas, menor RMS em janela de 100 ms acima de 0,077, correlação máxima com os primeiros 30 s do tema inicial de apenas 0,042 (o arranjo rejeitado tinha correlação global 0,962).

A criação local foi adotada porque o executável/helper do PixVerse não está instalado no ambiente. Não se tentou geração paga ou contornar a autenticação. A qualidade musical e a ausência perceptiva do ruído ainda exigem escuta humana; não se confunde a análise PCM com aprovação artística.

Reprodução:

```sh
python tools/audio/compose_phase_two.py /caminho/FluidR3_GM.sf2
```
