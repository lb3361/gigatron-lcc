#ifndef __GIGATRON_SOUND
#define __GIGATRON_SOUND

#include <gigatron/pragma.h>
#include <gigatron/sys.h>

/* -------------------- GENERAL */

/* Reset all four waveforms to their default values,
   0:noise 1:triangle 2:pulse 3:sawtooth */
extern void sound_reset_waveforms(void) __quickcall;

/* Sets the specified waveform to a sine wave.
   Usually argument `wave` is equal to 2 to replace the square wave. */
extern void sound_sine_waveform(int wave);

/* Sets the sound timer for the specified number of frames.
   No sound is produced unless the sound timer is greater than zero. */
#define sound_set_timer(frames) \
	do { soundTimer=frames; } while(0)

/* Enable all four sound channels.
   This is sometimes necessary because some roms do not
   properly set the channel mask in all circumstances.
   Also when channels are disabled, the remaining channels
   run at higher frequency. */
#define sound_enable_all_channels()\
	do { channelMask_v4 |= 3; } while(0)

/* Reset all four channels to null frequency, max volume, waveform `wave`.
   This differs from the Gigatron default state which has waveform 3
   but might change if one changes the startup note. */
extern void sound_reset(int wave) __quickcall;

/* Silences all channels by clearing their frequency keys. */
extern void sound_all_off(void) __quickcall;

/* Sets the channel frequency key to produce a sound around `freq` Hz.
   Returns the corresponding frequency key in 7.7 encoding.
   Argument `channel` must be in range 1..4.
   Argument `freq` must be in range 0 to 7800Hz.
   No checks are performed. */
extern word sound_freq(int channel, int frequency) __quickcall;

/* Convenience function that combines sound_freq, sound_vol, sound_waveform */
extern word sound_on(int channel, int frequency, int volume, int waveform) __quickcall;
#define sound_off(channel) sound_key(channel,0)

/* Sets the channel frequency key to produce the specified midi note.
   Returns the corresponding frequency key in 7.7 encoding.
   Argument `channel` must be in range 1..4.
   Argument `note` must be in range 12 (C0) to 106 (A#7).
   No checks are performed. */
extern word sound_note(int channel, int note) __quickcall;

/* Convenience function that combines sound_note, sound_volume, sound_waveform */
extern word note_on(int channel, int note, int volume, int waveform) __quickcall;
#define note_off(channel) sound_key(channel,0)

/* Macro to set the channel volume. */
#define sound_volume(channel, vol) \
	do { *(byte*)makep(channel,0xfa)=127-(vol); } while(0)

/* Macro to set the channel waveform. */
#define sound_waveform(channel, wave) \
	do { *(byte*)makep(channel,0xfb)=(wave)&3; } while(0)

/* Macro to set the channel frequency key */
#define sound_key(channel, key) \
	do { *(word*)makep(channel,0xfc)=(key); } while(0)

/* Macro to set the channel wavA and wavX parameters */
#define sound_mod(channel, wavXA) \
	do { *(word*)makep(channel,0xfa)=(wavXA); } while(0)

/* -------------------- MIDI */

/* Play midi music encoded in modified gtmidi format.
   Music plays autonomously using a vIrq handler (needs ROM>=v5a),
   Passing a null pointer stops the currently playing music.
   You can generate the modified midi data from at67's .gtmid
   file using the program gtmid2c provided with glcc.
   The .gtmid files themselves are derived from MidiTone files
   using at67's program `gtmidi` available in his Contrib dir. */
extern void midi_play(const byte *midi[]);

/* Tests whether midi music is playing. */
extern int midi_playing(void) __quickcall;

/* Arrange to play `midi` without interruption when the
   currently playing pieces terminates. This function succeeds
   when called while the last segment of the current piece is playing.
   Otherwise it returns zero. */
extern int midi_chain(const byte *midi[]);


/* -------------------- EXTRA */

/* Useful stuff copied from <gigatron/libc.h>.
   Must exactly match the declarations in <gigatron/libc.h> */
extern unsigned int _clock(void) __attribute__((quickcall));
extern void _wait(int n) __attribute__((quickcall));



#endif
