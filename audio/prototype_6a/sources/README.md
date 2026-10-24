# Fontes disponíveis e edição

- `prompts.json`: instruções completas da música e dos cinco efeitos; editáveis como texto.
- `provenance.json`: IDs das tarefas, modelo, parâmetros pedidos, base Git e custo observado. Não contém chaves, credenciais nem URLs assinadas temporárias.
- `prepare_audio.py`: receita de edição local; não chama serviços, não gasta créditos e não compõe por síntese. A composição já existe nos arquivos audíveis.
- `audio_metrics.json`: duração, formato, loudness, true peak e hashes dos renders realmente verificados.
- `generated/`: seis MP3 originais preservados no pacote de fontes para download; não duplicados em git.
- `../masters/`: WAV estéreo de 75 s, também somente no pacote de fontes.

Para editar, extraia o pacote completo. Os MP3 originais podem ser abertos em Audacity, REAPER ou outra estação de áudio; os cortes e a masterização podem ser refeitos modificando `prepare_audio.py` e executando:

```sh
python sources/prepare_audio.py
```

São necessários Python 3, FFmpeg e ffprobe no PATH. O script resolve os caminhos a partir de sua própria localização, independentemente da pasta corrente. Nenhuma regeneração paga é executada por esse comando.

**Limite de edição:** os originais são mixes de áudio, não projetos multitrack. O serviço não retornou stems, MIDI, partitura, soundfonts ou uma sessão de DAW. Não foram fabricados substitutos. Alterar notas individuais ou instrumentos isolados exigirá transcrição/rearranjo ou uma nova etapa de produção após aprovação. Converter um MP3 em WAV não o transforma em gravação sem perdas de origem.
