#include "coding.h"


static const int step_sizes[49] = { /* OKI table */
        16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45, 50,
        55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143, 157,
        173, 190,  209, 230, 253, 279, 307, 337, 371, 408, 449,
        494, 544, 598, 658, 724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552
};

static const int stex_indexes[16] = { /* IMA table */
        -1, -1, -1, -1, 2, 4, 6, 8,
        -1, -1, -1, -1, 2, 4, 6, 8
};


static void pcfx_expand_nibble(VGMSTREAMCHANNEL * stream, off_t byte_offset, int nibble_shift, int32_t * hist1, int32_t * step_index, int16_t *out_sample, int mode) {
    int code, step, delta;

    code = (read_8bit(byte_offset,stream->streamfile) >> nibble_shift) & 0xf;
    step = step_sizes[*step_index];

    delta = (code & 0x7);
    if (mode & 1) {
        if (step == 1552) /* bad last step_sizes value from OKI table */
            step = 1522;
        delta = step * (delta + 1) * 2;
    }
    else {
        delta = step * (delta + 1);
    }
    if (code & 0x8)
        delta = -delta;

    *step_index += stex_indexes[code];
    if (*step_index < 0) *step_index = 0;
    if (*step_index > 48) *step_index = 48;

    *hist1 += delta;
    if (*hist1 > 16383) *hist1 = 16383;
    if (*hist1 < -16384) *hist1 = -16384;

    if (mode & 1) {
        *out_sample = *hist1;
    } else {
        *out_sample = *hist1 << 1;
    }

    /* seems real HW does filtering here too */

    /* double volume since it clips at half */
    if (mode & 2) {
        *out_sample = *hist1 << 1;
    }
}


/* PC-FX ADPCM decoding, variation of OKI/Dialogic/VOX ADPCM. Based on mednafen/pcfx-music-dump.
 * Apparently most ADPCM was made with a buggy encoder, resulting in incorrect sound in real hardware
 * and sound clipped at half. Decoding can be controlled with modes:
 * - 0: hardware decoding (waveforms in many games will look wrong, ex. Der Langrisser track 032)
 * - 1: 'buggy encoder' decoding (waveforms will look fine)
 * - 2: hardware decoding with double volume (may clip?)
 * - 3: 'buggy encoder' decoding with double volume
 *
 * PC-FX ISOs don't have a standard filesystem nor file formats (raw data must be custom-ripped),
 * so it's needs GENH/TXTH. Sample rate can only be base_value divided by 1/2/3/4, where
 * base_value is approximately ~31468.5 (follows hardware clocks), mono or stereo-interleaved.
 */
void decode_pcfx(VGMSTREAMCHANNEL * stream, sample * outbuf, int channelspacing, int32_t first_sample, int32_t samples_to_do, int mode) {
    int i, sample_count = 0;
    int32_t hist1 = stream->adpcm_history1_32;
    int step_index = stream->adpcm_step_index;
    int16_t out_sample;

    for (i = first_sample; i < first_sample + samples_to_do; i++) {
        off_t byte_offset = stream->offset + i/2;
        int nibble_shift = (i&1?4:0); /* low nibble first */

        pcfx_expand_nibble(stream, byte_offset,nibble_shift, &hist1, &step_index, &out_sample, mode);
        outbuf[sample_count] = out_sample;
        sample_count += channelspacing;
    }

    stream->adpcm_history1_32 = hist1;
    stream->adpcm_step_index = step_index;
}

size_t pcfx_bytes_to_samples(size_t bytes, int channels) {
    /* 2 samples per byte (2 nibbles) in stereo or mono config */
    return bytes * 2 / channels;
}
