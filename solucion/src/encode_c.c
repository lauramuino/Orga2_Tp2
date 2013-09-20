void encode_c(unsigned char* src, unsigned char* dst, unsigned char* code, int size, int width, int height)
{
	unsigned char maskValue = 252;
	unsigned char maskCode = 3;
	unsigned char maskOp = 12;

	for (int i = 0; i < size*4; i+=4)
	{
		unsigned char n = code[i/4];
		for (int j = 0; j < 4; j++)
		{
			unsigned char a = src[i+j];
			unsigned char nValue = a & maskValue;
			unsigned char nOp = a & maskOp;
			unsigned char nV = n >> (j*2);
			nV = nV & maskCode;

			if(nOp == 0)
			{
				nValue |= nV;
			}
			if(nOp == 4)
			{
				nV--;
				nV &= maskCode;
				nValue |= nV;
			}
			if(nOp == 8)
			{
				nV++;
				nV &= maskCode;
				nValue |= nV;
			}
			if(nOp == 12)
			{
				nV = ~nV;
				nV &= maskCode;
				nValue |= nV;
			}

			dst[i+j] = nValue;
		}
	}
    for (int i=size*4; i<width*height*3; i++)
    {
        dst[i]=src[i];
    }
}
