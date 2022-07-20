Shader "Unlit/blinnPhong"
{
    Properties
    {
        // 블린 퐁에서 필요한 4개의 텍스쳐 (디퓨즈맵, 스펙큘러맵, 노말맵, 큐브맵)를 담는 유니폼 변수를 위한 인터페이스 추가
        _Diffuse ("Texture", 2D) = "white" {}
        _Normal ("Normal", 2D) = "blue" {}
        _Specular ("Specular", 2D) = "black" {} // 스펙큘러맵의 기본값은 아무런 스펙큘러(광택)을 받지 않는 검정색으로 지정
        _Environment ("Environment", Cube) = "white" {} // 유니티 쉐이더에서 큐브맵 텍스쳐 지정 시 'Cube' 타입으로 선언함.
    }
    SubShader
    {
        // 유니티 Tags 블록에 추가하는 "Queue" 는 유니티가 해당 쉐이더가 적용된 메쉬를 그리는 순서를 정의함.
        // 유니티 쉐이더에서도 배웠지만, 항상 불투명 오브젝트들을 다 그리고 나서 반투명 오브젝트들을 그린다고 했었지?
        // 유니티에서 명시적으로 Queue 를 지정하지 않을 경우, 기본값으로 "Geometry" 를 할당하는데, 당연히 불투명 오브젝트일 거고, 이 기본값을 명시했을 뿐임.
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100

        Pass
        {
            /*
                각 Pass (즉, 각 메쉬 단위) 블록에서도 Tags 블록을 각각 지정할 수 있음.
                여기서 LightMode 는 해당 패스가 라이팅 시스템과 어떻게 상호작용할 것인지를 정의함.

                예를 들어, 아래와 같이 "ForwardBase" 라고 명시할 경우,
                멀티라이트를 포워드 렌더링으로 구현했을 때,
                각 라이팅 유형마다 메쉬들을 각각 그려서 알파 블렌딩으로 중첩했었지?

                그 때의 각각의 중첩 블렌딩의 대상이 되는 불투명한 메쉬들을 
                포워드 렌더링의 '베이스패스' 라고 하며, 

                유니티 쉐이더에서는 이러한 패스를 "ForwardBase" 라는
                키워드로 지정함.

                참고로 포워드 렌더링은,
                각 라이트마다 여러 개의 메쉬(패스)를 생성해서
                블렌딩으로 중첩하는 방식이라면,

                디퍼드 렌더링은,
                모든 오브젝트들을 다 그린 다음에,
                백 버퍼에 그려진 픽셀들만, 즉,
                화면에 그려지는 픽셀들에 대해서만 라이팅을 계산하는
                렌더링 방식이였지!
            */
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // 해당 패스 블록에서 지정했듯이, 이 패스를 라이팅 시스템에서 
            // 포워드 베이스 패스로 사용할 수 있도록 유니티 쉐이더 컴파일러에게 요청하는 pragma 문 
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc" // 유니티 내장 셰이더함수를 사용하기 위해 이들 내장함수가 담긴 헬퍼파일을 include(import)시킴.

            // 버텍스 셰이더 함수에서 입력받는 구조체 (즉, 각 버텍스의 기본 attribute 데이터들이 정의되어 있음.)
            struct vIN
            {
                float4 vertex : POSITION; // 버텍스 위치 데이터
                float3 normal : NORMAL; // 버텍스 노말 벡터 데이터
                float3 tangent : TANGENT; // 버텍스 탄젠트 벡터 데이터
                float2 uv : TEXCOORD0; // 버텍스 uv 좌표 데이터 (TEXCOORD0 시맨틱에서 0이 의미하는 바는, 버텍스 하나가 여러 개의 UV좌표 세트를 가질 경우, 각 UV좌표 세트마다 번호를 부여하여 구분하기 위함.)
            };

            // 버텍스 셰이더에서 보간되어 다음 파이프라인들( ex> 프래그먼트 셰이더 )로 출력되는 구조체 (GLSL out 변수처럼 보간을 거쳐서 프래그먼트 셰이더로 전달됨)
            struct vOUT
            {
                float4 pos : SV_POSITION; // 단색 셰이더에서 지정해줬듯이 버텍스 위치 데이터가 보간되어 넘어가는 변수

                /*
                    여기서부터 살짝 의문이 들 수 있음. 
                    왜 3*3 TBN 행렬, worldPos 같은 변수들에 TEXCOORD 같은 시맨틱이 붙을까?

                    기본적으로 유니티 셰이더에서는
                    버텍스 출력 구조체에 고정밀도 데이터 (즉, float 타입의 실수 데이터)를 담을 때,
                    TEXCOORD 시맨틱을 사용함.

                    그니까 꼭 텍스쳐에 사용하는 UV 데이터에 대해서만
                    TEXCOORD 라는 시맨틱을 사용하는 건 아니라는 뜻!

                    그래서 TEXCOORD 는 내부적으로 float4 형태의 데이터 타입을 취하고 있음.
                */

                // 얘는 3*3 행렬을 표현해야 하기 때문에, float4 타입의 TEXCOORD가 3개 필요하겠지?
                // 그래서 선언한 TEXCOORD0 부터 TEXCOORD1, TEXCOORD2 까지의 UV 좌표 세트를 모조리 가져다 써야하기 때문에
                // 아래의 uv 변수는 TEXCOORD3 부터 사용할 수 있게 되는 것임.
                // 이게 위에서 이야기했던 하나의 버텍스 데이터가 여러 개의 UV 좌표 세트를 가져다 쓰는 경우라고 보면 됨!
                float3x3 tbn : TEXCOORD0;

                float2 uv : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
            };

            // 버텍스 함수 (GLSL의 버텍스 셰이더와 마찬가지로, 월드공간의 TBN 행렬, UV좌표, 위치좌표 등을 구한 뒤, 프래그먼트 셰이더로 보간해서 넘기는 역할은 동일함.)
            vOUT vert (vIN v)
            {
                vOUT o; // 버텍스 출력 구조체를 o 라는 이름의 변수로 가져옴.
                o.pos = UnityObjectToClipPos(v.vertex); // 버텍스 위치좌표에 MVP 행렬을 곱해 클립공간 좌표계로 변환해주는 유니티 내장함수 사용
                o.uv = v.uv; // 입력 구조체의 버텍스 uv좌표 데이터를 출력 구조체의 uv좌표 데이터로 넘겨줌. -> 프래그먼트 함수에서 보간될거임.

                // 월드공간 노말벡터, 탄젠트벡터, 바이탄젠트벡터를 구해 TBN 행렬을 만듦.
                float3 worldNormal = UnityObjectToWorldNormal(v.normal); // 버텍스 노말벡터에 노말행렬을 곱해 월드공간 노멀벡터로 변환해주는 유니티 내장함수 사용
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz); // 버텍스 탄젠트벡터를 월드공간 탄젠트벡터로 변환해주는 (꼭 탄젠트벡터가 아니여도 방향을 갖는 벡터데이터 자체를 변환해주는 거 같음) 유니티 내장함수 사용
                float3 worldBitan = cross(worldNormal, worldTangent); // 월드공간 노말벡터와 월드공간 탄젠트벡터를 외적계산하여 월드공간 바이탄젠트 벡터를 구함.

                // 유니티는 현재 오브젝트 공간에서 월드공간으로 위치좌표를 변환해주는 내장함수가 없기 때문에,
                // 모델행렬을 직접 버텍스 위치좌표에 곱해줘서 월드공간 좌표계로 변환해주는 거 같음.
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.tbn = float3x3(worldTangent, worldBitan, worldNormal); // 월드공간 노말벡터, 탄젠트벡터, 바이탄젠트 벡터를 3*3 행렬로 묶어서 TBN 행렬로 만든 뒤, 출력구조체에 할당해서 보간시켜 전달함.

                return o; // 출력 구조체의 변수들을 모두 계산하여 다음 파이프라인으로 전달함. (프래그먼트 함수에서 보간되어 전달될거임.)
            }

            // 프래그먼트 함수에서 사용할 유니폼 변수 선언
            sampler2D _Normal;
            sampler2D _Diffuse;
            sampler2D _Specular;
            samplerCUBE _Environment;
            float4 _LightColor0; // 유니티 현재 라이트 색상을 담고있는 내장 변수.

            // 프래그먼트 함수
            fixed4 frag(vOUT i) : SV_Target
            {
                // 조명계산에 필요한 일반벡터들을 먼저 구함
                float3 unpackNormal = UnpackNormal(tex2D(_Normal, i.uv)); // 노말맵에서 텍셀값을 샘플링해온 뒤, -1 ~ 1 사이의 탄젠트공간 노멀벡터로 맵핑해주는 유니티 내장함수 UnpackNormal() 사용.
                // 참고로, 이런 UnpackNormal() 같은 유니티의 ShaderLab 내장함수가 중요한 이유는, 크로스 플랫폼에서 다양한 셰이딩 언어로 빌드하더라도, 이 내장함수를 사용하면 각각의 플랫폼에 맞게 노말맵을 샘플링 및 맵핑해서 탄젠트공간 노멀벡터로 바꿔주는 코드로 알아서 변환시켜주기 때문임!

                float3 nrm = normalize(mul(transpose(i.tbn), unpackNormal)); // 노말맵에서 샘플링 및 맵핑한 탄젠트공간 노멀벡터에 TBN 행렬을 곱해서 월드공간 노멀벡터로 만듦. (이때, Cg 셰이더는 '행 우선 행렬'을 사용하므로, 열 우선 행렬인 현재의 TBN 행렬을 transpose() 함수로 전치행렬로 변환해 줌.)
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos); // <월드공간 카메라좌표(유니티 내장변수) - 월드공간 프래그먼트 위치좌표> 를 통해 카메라에서 각 프래그먼트까지의 카메라벡터를 구함.
                float3 halfVec = normalize(viewDir + _WorldSpaceLightPos0.xyz); // <월드공간 디렉셔널라이트 벡터(유니티 내장변수) + 월드공간 카메라벡터> 를 통해 카메라벡터와 조명벡터 사이의 하프벡터를 구함. (블린 퐁에서는 반사벡터 대신 하프벡터를 구해서 스펙큘러를 계산했었지?)
                float3 env = texCUBE(_Environment, reflect(-viewDir, nrm)).rgb; // 뒤집은 카메라벡터와 월드공간 노멀벡터를 기준으로 반사벡터를 구해서(카메라를 기준으로 해당 프래그먼트에 맺힐 큐브맵의 텍셀을 역추적하는 원리였지?) 큐브맵 텍스쳐를 샘플링할 float3 벡터를 구하고, 이거로 큐브맵 텍스쳐를 샘플링함.
                float3 sceneLight = lerp(_LightColor0, env + _LightColor0 * 0.5, 0.5); // GLSL 에서 mix() 내장함수로 큐브맵 텍셀값과 조명색상을 적절한 비율로 섞어줬던 것처럼, 여기서는 lerp() 유니티 내장함수로 섞어주고 있음. 이름만 다를 뿐 둘은 사실상 같은 일을 해주는 함수!

                // 라이팅 계산
                float diffAmt = max(dot(nrm, _WorldSpaceLightPos0.xyz), 0.0); // 디퓨즈 라이팅 계산 : 월드공간 노멀벡터와 월드공간 디렉셔널라이트 벡터(유니티 내장변수)를 내적계산하고, 내적결과값에서 음수를 제거
                float specAmt = max(dot(halfVec, nrm), 0.0); // 스펙큘러 라이팅 계산 : 블린 퐁 공식에서는 하프벡터와 월드공간 노멀벡터를 내적계산하고, 내적결과값에서 음수를 제거해서 스펙큘러 라이팅을 계산했었지?

                // 텍스쳐 샘플링
                float4 tex = tex2D(_Diffuse, i.uv); // 디퓨즈맵 (물체의 원색상 텍스쳐) 샘플링
                float4 specMask = tex2D(_Specular, i.uv); // 스펙큘러맵 (스펙큘러 재질을 적용할 영역만 흰색으로 마스킹한 텍스쳐) 샘플링
                
                // 스펙큘러 색상 계산
                float3 specCol = specMask.rgb * specAmt; // 스펙큘러맵에 마스킹된 영역 위주로 스펙큘러 라이팅이 계산될 수 있도록 곱해줌.

                // 최종 라이팅 성분 계산
                float3 finalDiffuse = sceneLight * diffAmt * tex.rgb; // <씬의 조명값(큐브맵 반사조명과 현재 씬의 조명색상이 섞임) * 디퓨즈 라이팅 * 디퓨즈맵 (물체의)원색상> 으로 최종 디퓨즈 값 계산
                float3 finalSpec = sceneLight * specCol; // <씬의 조명값(큐브맵 반사조명과 현재 씬의 조명색상이 섞임) * 마스킹 처리된 스펙큘러 라이팅> 으로 최종 스펙큘러 값 계산
                float3 finalAmbient = UNITY_LIGHTMODEL_AMBIENT.rgb * tex.rgb; // <현재 씬의 환경광(유니티 내장변수) * 디퓨즈맵 (물체의)원색상> 으로 최종 앰비언트 값 계산

                // 라이팅 결과를 합쳐서 최종 프래그먼트 색상값 리턴 (glsl에서는 최종 색상값을 out 변수 또는 gl_FragColor 에 할당했었지?)
                return float4(finalDiffuse + finalSpec + finalAmbient, 1.0);
            }
            ENDCG
        }
    }
}
