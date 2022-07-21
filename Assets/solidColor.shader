// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/solidColor"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1) // _Color ��� �̸��� ������ ������ �������̽��κ��� ���� �޾� ����� �� �ֵ��� Property �߰�.
    }
    SubShader
    {
        // �ܻ� ���̴��� ���� ���� ���̴� (������ ���̴�)�� ����� ����, SubShader ��Ͽ��� �� ���̴��� ����� �޽��� �׷����� ����, ��, Queue �� "Transparent" �� �����ؾ� ��. -> �̰� ����� ������ ����ä���� ����� �ϱ� ������!
        Tags { "Queue" = "Transparent" }
        LOD 100

        Pass
        {
            // ���� ���ϴ� ���� ��� ������ ���� �ش� Pass ��Ͽ� ��������� ��!
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM

            // ���ؽ� ���̴��� �����׸�Ʈ ���̴� ������ main() �Լ� �̸��� #pragma ���þ�� ������ ��.
            #pragma vertex vert
            #pragma fragment frag

            // ���ؽ� ���̴� �Է� ����ü
            struct appdata
            {   
                // vertex ��� ������ '���ؽ� ��ġ ������'�� ��� �������� ���ϴ� �ø�ƽ 'POSITION'�� ������.
                float4 vertex : POSITION;
            };

            // ���ؽ� ���̴� ��� ����ü
            struct v2f
            {
                // '���ؽ� ��ġ ������' POSITION �� ���� ������������ ���� �����׸�Ʈ ���̴��� �������� ��������� ǥ���ϱ� ����
                // ��������� �����, SV_POSITION �̶�� �ø�ƽ�� ������. �̶�, SV �� 'System Value' �� ���ڷν�, 
                // ���ؽ� ���̴� �� �����׸�Ʈ ���̴� �̿��� ���������� (��, primitive assembly �ܰ�� ������ȭ �ܰ�)���� ���� ���������� ǥ���� �� ����.
                float4 vertex : SV_POSITION;
            };

            // ����ڷκ��� �Է¹��� ������ ��� ������ ���� ���� 
            // ����Ƽ���� ����ü �Ǵ� �Լ� �ۿ��� ����� ������ ������ GLSL �� �޸� ���ؽ� ���̴� �� �����׸�Ʈ ���̴� ��ο��� �ش� ������ ������ ������ �� ����.
            float4 _Color; 

            v2f vert(appdata v) {
                // ���ؽ� ������ ���⿡ �´�.
                v2f o;

                // ���ؽ� ��ġ �����͸� ����Ƽ ���� MVP ��İ� ���� Ŭ����ǥ��� ��ȯ��. 
                // GLSL �� �ٸ� ����, ��İ� ���͸� ���� �� mul() �̶�� ������ �����Լ��� ����Ѵٴ� ��!
                // ��, MVP ��� ���� ����Ƽ���� �⺻ �������ֹǷ�, �ռ� ����� �ʿ䰡 ���ٴ� ��!
                // mul(UNITY_MATRIX_MVP, ���ؽ� ��ġ ������) �̰Ű� UnityObjectToClipPos(���ؽ� ��ġ ������) �� �ٲ��� ��. ����� �������� �̷��� �ۼ��Ǿ� ����.
                o.vertex = UnityObjectToClipPos(v.vertex); 
                return o; // glsl ������ gl_Position �� ���� ��ȯ�� ��ġ��ǥ�� �Ҵ��߾�����, ���⼭�� ���� ���� ��������� ��.
            }

            /*
                cg ���� �����׸�Ʈ ���̴��� 
                1. SV_Target
                2. SV_Depth 
                �� ���� �ø�ƽ�� ���� �� ����.

                SV_Target �� ������ ���ۿ� ���� �����͸� ���ٴ� ���̰�,
                SV_Depth �� ���� ���ۿ� ���� ���ϰ��� ���ٴ� ����.

                �Ϲ����� ��Ȳ���� SV_Depth �� ����� ���� ���� �����Ƿ�,
                �������ϸ� SV_Target �ø�ƽ�� �����ϰ� ����ϸ� �ȴٰ� ��.
            */
            float4 frag(v2f i) : SV_Target{
                // �����׸�Ʈ ������ ���⿡ �´�.
                return _Color; // out, gl_FragColor � ���� ������ �Ҵ��ϴ� ���, ���������� ���� ���� ��������� ��.
            }
            ENDCG
        }
    }
}
