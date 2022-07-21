// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/solidColor"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1) // _Color 라는 이름의 유니폼 변수에 인터페이스로부터 값을 받아 사용할 수 있도록 Property 추가.
    }
    SubShader
    {
        // 단색 셰이더를 알파 블렌딩 셰이더 (반투명 셰이더)로 만들기 위해, SubShader 블록에서 이 쉐이더가 적용된 메쉬가 그려지는 순서, 즉, Queue 를 "Transparent" 로 지정해야 함. -> 이걸 해줘야 색상의 알파채널이 기능을 하기 시작함!
        Tags { "Queue" = "Transparent" }
        LOD 100

        Pass
        {
            // 이후 원하는 블렌딩 모드 공식을 직접 해당 Pass 블록에 지정해줘야 함!
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM

            // 버텍스 셰이더와 프래그먼트 셰이더 각각의 main() 함수 이름을 #pragma 지시어로 지정해 줌.
            #pragma vertex vert
            #pragma fragment frag

            // 버텍스 셰이더 입력 구조체
            struct appdata
            {   
                // vertex 라는 변수가 '버텍스 위치 데이터'를 담는 변수임을 뜻하는 시맨틱 'POSITION'을 선언함.
                float4 vertex : POSITION;
            };

            // 버텍스 셰이더 출력 구조체
            struct v2f
            {
                // '버텍스 위치 데이터' POSITION 을 여러 파이프라인을 거쳐 프래그먼트 셰이더로 전달함을 명시적으로 표현하기 위해
                // 멤버변수를 만들고, SV_POSITION 이라는 시맨틱을 선언함. 이때, SV 는 'System Value' 의 약자로써, 
                // 버텍스 셰이더 및 프래그먼트 셰이더 이외의 파이프라인 (즉, primitive assembly 단계와 래스터화 단계)에서 사용될 데이터임을 표시할 때 붙임.
                float4 vertex : SV_POSITION;
            };

            // 사용자로부터 입력받은 색상값이 담긴 유니폼 변수 선언 
            // 유니티에서 구조체 또는 함수 밖에서 선언된 유니폼 변수는 GLSL 과 달리 버텍스 셰이더 및 프래그먼트 셰이더 모두에서 해당 유니폼 변수에 접근할 수 있음.
            float4 _Color; 

            v2f vert(appdata v) {
                // 버텍스 로직은 여기에 온다.
                v2f o;

                // 버텍스 위치 데이터를 유니티 내장 MVP 행렬과 곱해 클립좌표계로 변환함. 
                // GLSL 과 다른 점은, 행렬과 벡터를 곱할 때 mul() 이라는 별도의 내장함수를 사용한다는 것!
                // 또, MVP 행렬 또한 유니티에서 기본 제공해주므로, 손수 계산할 필요가 없다는 것!
                // mul(UNITY_MATRIX_MVP, 버텍스 위치 데이터) 이거가 UnityObjectToClipPos(버텍스 위치 데이터) 로 바꼈나 봄. 깃허브 예제에도 이렇게 작성되어 있음.
                o.vertex = UnityObjectToClipPos(v.vertex); 
                return o; // glsl 에서는 gl_Position 에 최종 변환된 위치좌표를 할당했었지만, 여기서는 값을 직접 리턴해줘야 함.
            }

            /*
                cg 에서 프래그먼트 셰이더는 
                1. SV_Target
                2. SV_Depth 
                두 개의 시맨틱을 가질 수 있음.

                SV_Target 은 렌더링 버퍼에 색상 데이터를 쓴다는 것이고,
                SV_Depth 는 깊이 버퍼에 직접 리턴값을 쓴다는 뜻임.

                일반적인 상황에서 SV_Depth 를 사용할 일은 거의 없으므로,
                어지간하면 SV_Target 시맨틱을 지정하고 사용하면 된다고 함.
            */
            float4 frag(v2f i) : SV_Target{
                // 프래그먼트 로직은 여기에 온다.
                return _Color; // out, gl_FragColor 등에 최종 색상값을 할당하는 대신, 마찬가지로 값을 직접 리턴해줘야 함.
            }
            ENDCG
        }
    }
}
