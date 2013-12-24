using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace YourServer
{
    public partial class RequestProduct : System.Web.UI.Page
    {
        /// <summary> iTunes Storeの本環境URL </summary>
        private readonly Uri buyUri     = new Uri("https://buy.itunes.apple.com/verifyReceipt");
        /// <summary> iTines StoreのSandbox環境URL </summary>
        private readonly Uri sandboxUri = new Uri("https://sandbox.itunes.apple.com/verifyReceipt");

        protected async void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                // http://xxx.xxx.xxx.xxx/RequestProduct.aspx?tran=<transactionReceipt値>
                var transactionReceipt = Request["tran"];
                if (!string.IsNullOrEmpty(transactionReceipt))
                {
                    // 本Webアプリ側へリクエストを送信しているiOSアプリが、本環境向けかSandbox向けか、
                    // このWebアプリ上で判断できない。まずiTunes Storeの本環境にレシートを確認する。
                    var receipt = await ConfirmReceiptToiTunesStore(buyUri, transactionReceipt);
                    // 本環境へレシート確認し応答ステータスが21007ならSandboxのレシートという意味
                    // Sandbox環境へ問い合わせしなおす
                    if (receipt.Status == 21007)
                    {
                        receipt = await ConfirmReceiptToiTunesStore(sandboxUri, transactionReceipt);
                    }

                    // ステータスが0＝レシート確認が取れた場合、消耗型プロダクトの加算数を5にして返戻
                    int itemCount = 0;
                    if (receipt.Status == 0)
                    {
                        itemCount = 5;
                    }
                   
                    // レスポンス生成
                    Response.Clear();   
                    Response.ContentType = "text/plain";
                    Response.Write(itemCount.ToString());
                    Response.Flush();
                }
            }

            throw new Exception(); // Internal Server Error
        }

        /// <summary>
        /// iTunes Storeへレシートを確認し、その応答結果をReceiptDataクラスで応答する
        /// </summary>
        /// <param name="uri">レシート確認先URL</param>
        /// <param name="transactionReceipt">確認するレシート値</param>
        /// <returns></returns>
        public async Task<ReceiptData> ConfirmReceiptToiTunesStore(Uri uri, string transactionReceipt)
        {
            // iTunes Storeへレシート確認するためのHTTPクライアント
            using (var handler = new HttpClientHandler())
            using (var client = new HttpClient(handler))
            {
                // iTunes Storeへレシート確認するための送信データを生成する
                var json = string.Format("{{\"receipt-data\" : \"{0}\"}}", transactionReceipt);
                var content = new StringContent(json);
                // iTunes StoreへHTTPリクエスト、レスポンスを取得する
                var response = await client.PostAsync(uri, content).Result.Content.ReadAsStringAsync();
                // レスポンスはJSONフォーマットを期待しているので、JSONオブジェクトへ変換
                var receiptdata = ToReceiptData(response);
                // JSONオブジェクトを返戻
                return receiptdata;
            }
        }

        /// <summary>
        /// JSONデシリアライザ
        /// ReceiptDataクラスに変換する
        /// </summary>
        /// <param name="json"></param>
        /// <returns></returns>
        public ReceiptData ToReceiptData(string json)
        {
            var jsonSerializer = new DataContractJsonSerializer(typeof(ReceiptData));
            using (MemoryStream ms = new MemoryStream(Encoding.ASCII.GetBytes(json)))
            {
                return (ReceiptData)jsonSerializer.ReadObject(ms);
            }
        }

        /// <summary>
        /// iTuns Storeのレスポンス（JSON）に対応するクラス
        /// </summary>
        [DataContract]
        public class ReceiptData
        {
            [DataMember(Name = "status")]
            public int Status { get; set; }
        }
    }
}