using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Ripple : MonoBehaviour
{

    public Camera mainCamera;
    public RenderTexture InteractiveRT;//交互RT
    public RenderTexture PrevRT;//上一帧
    public RenderTexture CurrentRT;//当前帧
    public RenderTexture TempRT;//临时RT
    public Shader DrawShader;
    public Shader RippleShader;//涟漪计算shader
    public Shader AddShader;
    private Material RippleMat;
    private Material DrawMat;
    private Material AddMat;

    [Range(0f, 1f)] public float DrawRadius = 0.2f;

    public int TextureSize = 512;
    
    [Range(0f, 0.1f)]
    public float RippleTime = 0.1f;

    [Range(0.8f, 0.99f)] public float RippleDecrese = 0.97f;
    // Start is called before the first frame update
    void Start()
    {
        mainCamera = Camera.main;
        
        PrevRT = CreateRT();
        CurrentRT = CreateRT();
        TempRT = CreateRT();
        
        DrawMat = new Material(DrawShader);
        RippleMat = new Material(RippleShader);
        AddMat = new Material(AddShader);
        
        GetComponent<Renderer>().material.mainTexture = CurrentRT;

        StartCoroutine(RippleCoroutine());

    }

    public RenderTexture CreateRT()
    {
        RenderTexture rt = new RenderTexture(TextureSize, TextureSize, 0, RenderTextureFormat.RFloat);
        rt.Create();
        return rt;
    }
    
    private Vector3 lastPos;

    // Update is called once per frame
    void Update()
    {
        AddMat.SetTexture("_Tex1",InteractiveRT);
        AddMat.SetTexture("_Tex2",CurrentRT);
        Graphics.Blit(null, TempRT, AddMat);
        RenderTexture rt0 = TempRT;
        TempRT = CurrentRT; 
        CurrentRT = rt0;
    }

    private IEnumerator RippleCoroutine()
    {
        while (true)
        {
            yield return new WaitForSeconds(RippleTime);
            //计算涟漪
            RippleMat.SetFloat("_RippleDecrese", RippleDecrese);
            RippleMat.SetTexture("_PrevRT",PrevRT);
            RippleMat.SetTexture("_CurrentRT",CurrentRT);
            Graphics.Blit(null,TempRT, RippleMat);
            
            //交换
            Graphics.Blit(TempRT, PrevRT);
            RenderTexture rt = PrevRT;
            PrevRT = CurrentRT;
            CurrentRT = rt; 
        }
        
    }
}
