#include "midi_processor.h"

const uint8_t midi_processor::end_of_track[2] = {0xFF, 0x2F};
const uint8_t midi_processor::loop_start[11] = {0xFF, 0x06, 'l', 'o', 'o', 'p', 'S', 't', 'a', 'r', 't'};
const uint8_t midi_processor::loop_end[9] =    {0xFF, 0x06, 'l', 'o', 'o', 'p', 'E', 'n', 'd'};

int midi_processor::decode_delta( std::vector<uint8_t>::const_iterator & it )
{
	int delta = 0;
	unsigned char byte;
	do
	{
        byte = *it++;
		delta = ( delta << 7 ) + ( byte & 0x7F );
	}
	while ( byte & 0x80 );
	return delta;
}

bool midi_processor::process_file( std::vector<uint8_t> const& p_file, const char * p_extension, midi_container & p_out )
{
    if ( is_standard_midi( p_file ) )
	{
        return process_standard_midi( p_file, p_out );
	}
    else if ( is_riff_midi( p_file ) )
	{
        return process_riff_midi( p_file, p_out );
	}
    else if ( is_hmp( p_file ) )
	{
        return process_hmp( p_file, p_out );
    }
    else if ( is_hmi( p_file ) )
	{
        return process_hmi( p_file, p_out );
    }
    else if ( is_xmi( p_file ) )
	{
        return process_xmi( p_file, p_out );
    }
    else if ( is_mus( p_file ) )
	{
        return process_mus( p_file, p_out );
    }
    else if ( is_mids( p_file ) )
	{
        return process_mids( p_file, p_out );
    }
    else if ( is_lds( p_file, p_extension ) )
	{
        return process_lds( p_file, p_out );
    }
    else if ( is_gmf( p_file ) )
	{
        return process_gmf( p_file, p_out );
    }
    else return false;
}

bool midi_processor::process_syx_file( std::vector<uint8_t> const& p_file, midi_container & p_out )
{
    if ( is_syx( p_file ) )
    {
        return process_syx( p_file, p_out );
    }
    else return false;
}